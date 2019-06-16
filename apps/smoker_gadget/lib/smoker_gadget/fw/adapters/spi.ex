defmodule SmokerGadget.Fw.Adapters.Spi do
  @moduledoc false

  alias Circuits.SPI

  @behaviour SmokerGadget.Fw.Adapters.SpiBehaviour

  @impl true
  @spec open(String.t, charlist) :: {:ok, reference}
  def open(device, options), do: SPI.open(device, options)

  @impl true
  @spec transfer(reference, binary) :: {:ok, binary}
  def transfer(ref, data), do: SPI.transfer(ref, data)
end
