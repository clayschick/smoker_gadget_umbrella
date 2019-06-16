defmodule SmokerGadget.Fw.Adapters.Pwm do
  @moduledoc false

  alias Pigpiox.Pwm

  @behaviour SmokerGadget.Fw.Adapters.PwmBehaviour

  @default_pin 18
  @default_frequency 25_000

  @impl true
  @spec set_duty_cycle(integer) :: :ok | {:error, String.t}
  def set_duty_cycle(level \\ 0) do
    config = Application.get_env(:fw, Fw.Fan, [])
    pin = config[:pwm_pin] || @default_pin
    frequency = config[:pwm_frequency] || @default_frequency

    case Pwm.hardware_pwm(pin, frequency, level) do
      :ok -> :ok
      {:error, error_atom} -> {:error, to_string(error_atom)}
    end
  end
end
