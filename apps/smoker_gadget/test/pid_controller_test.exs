defmodule SmokerGadget.PidControllerTest do
  use ExUnit.Case

  alias SmokerGadget.Pid.Controller
  alias SmokerGadget.Pid.ControllerAgent

  test "PID controller output" do
    expected_output = 4.369400356619089
    temp = 72.17413285784122
    setpoint = 78
    kp = 0.5
    ki = 0.25
    kd = 0.25

    # The pid_control_channel in the UI sets the PID state like this
    # when it handles the controller start message
    :ok = ControllerAgent.init(setpoint, kp, ki, kd)

    assert expected_output == Controller.evaluate(temp)
  end
end
