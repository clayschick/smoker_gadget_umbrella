defmodule SmokerGadget.Fw.Fan do
  @moduledoc """
  Using the Pigpiox library to adjust a 4-wire PWM fan.

  Currently using a 4-pin PWM enabled fan. The PWM pin on the
  fan is `5v` and `25_000Hz` frequency.

  The PI is only `3.3v` output but is enough to drive the PWM.

  The max frequency is 1_000_000. At a frequency of 25_000 the
  fan will start at a dutycycle of 94_000 and stops at 50_000.
  NOTE: the example values above need updated

  The fan does not start and stop at the same dutycycle value.
  """

  require Logger

  @default_adapter SmokerGadget.Fw.Adapters.Pwm
  @default_multiplier 1000

  @spec adjust(number) :: :ok | {:error, any}
  def adjust(pid_output) do
    config = Application.get_env(:fw, Fw.Fan, [])
    adapter = config[:pwm_adapter] || @default_adapter
    pwm_frequency_multiplier = config[:pwm_frequency_multiplier] || @default_multiplier

    level = min(pid_output * pwm_frequency_multiplier, 1_000_000)

    Logger.debug("PWM duty_cycle level: #{level}")

    case adapter.set_duty_cycle(trunc(level)) do
      :ok -> :ok
      {:error, msg} -> Logger.error(msg)
    end
  end

  @spec stop :: :ok | {:error, any}
  def stop, do: adjust(0)
end
