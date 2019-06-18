defmodule SmokerGadget.Fw.Temperature do
@moduledoc """
  Using the Circuits.SPI library to read the RTD value from
  the MAX31865 breakout board.

  I got the math from the Adafruit python library.

  I'd like to keep the ref in a Registry and use the
  Agent to hold the temp value. However, I'd also like
  to propagate any errors up to the caller.
  """
  use Agent

  require Logger

  @default_adapter SmokerGadget.Fw.Adapters.Spi
  @default_device_bus "spidev0.0"
  @default_mode 1
  @default_speed_hz 500_000

  @doc """
  Use Keyword.fetch!/2 for required fields in the options list
  """
  @spec start_link(list) :: any
  def start_link(_option_list \\ []) do
    Agent.start_link(&connect/0, name: __MODULE__)
  end

  @doc """
  Connect to the SPI device on the main SPI bus.

  The MAX31865 uses mode 1 or 3.

  The speed is the same as in the Adafruit python library.

  The configuration (register 0x80) is a one time setup
  for 3-wire config and auto conversion mode.
  """
  @spec connect :: %{ref: reference, adapter: module}
  def connect do
    config = Application.get_env(:smoker_gadget, Fw.Temperature, [])
    adapter = config[:spi_adapter] || @default_adapter
    device_bus = config[:spi_device_bus] || @default_device_bus
    mode = config[:spi_mode] || @default_mode
    speed_hz = config[:spi_speed_hz] || @default_speed_hz

    {:ok, ref} = adapter.open(device_bus, mode: mode, speed_hz: speed_hz)

    _ = adapter.transfer(ref, <<0x80, 0xD0>>)

    %{ref: ref, adapter: adapter}
  end

  @doc """
  Read from the data registers on the IC.

  The data register value on the MAX31865 is 0x01 and the
  transfer will return 3 bytes.
  - the first byte is ignored - not sure why this byte exists
  - the next 15 bits represent the resistance value
  - the last bit is the fault status flag

  The interval value is used in the :timer to slow down
  the stream because in the datasheet it says:

  > Note that a single conversion requires approximately 52ms
  > in 60Hz filter mode or 62.5ms in 50Hz filter mode to complete.
  """
  @spec read :: float
  def read do
    %{ref: ref, adapter: adapter} = Agent.get(__MODULE__, & &1)

    {:ok, <<_::size(8), digits::size(15), fault_bit::size(1)>>} =
      adapter.transfer(ref, <<0x01, 0x00, 0x00>>)

    resistance = digits / 32_768 * 430

    z1 = -3.9083e-3
    z2 = 3.9083e-3 * 3.9083e-3 - 4 * -5.775e-7
    z3 = 4 * -5.775e-7 / 100
    z4 = 2 * -5.775e-7
    temp = z2 + z3 * resistance
    temp = (:math.sqrt(temp) + z1) / z4
    f_temp = temp * 9 / 5 + 32

    Logger.debug("Temperature: #{f_temp}")

    case fault_bit do
      1 -> "Fault bit set"
      0 -> f_temp
    end
  end

  @doc """
  Generates a stream of temperature values.
  """
  @spec stream :: Enumerable.t
  def stream do
    Stream.repeatedly(fn -> read() end)
  end
end
