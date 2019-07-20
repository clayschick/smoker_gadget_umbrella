defmodule SmokerGadget.Fw.Adapters.PwmTest do
  @moduledoc false

  alias SmokerGadget.Fw.Adapters.SpiTest

  @behaviour SmokerGadget.Fw.Adapters.PwmBehaviour

  @impl true
  @spec set_duty_cycle(integer) :: :ok
  def set_duty_cycle(pid_output) do
    SpiTest.fake_temp_adjustment(pid_output)
    :ok
  end
end
