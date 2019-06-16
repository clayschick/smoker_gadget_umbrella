defmodule SmokerGadget.Fw.Adapters.PwmBehaviour do
  @moduledoc """
  Specification for PWM behaviour
  """
  @callback set_duty_cycle(level :: integer) :: :ok | {:error, String.t}
end
