defmodule SmokerGadgetWeb.PidControlChannel do
  @moduledoc """
  Channel module for handling control messages from the UI.

  This module talks directly to the Pid.ControllerAgent and updates it's
  dependent state values. There is a certain amount of validation
  done here since this is the closest to the UI arguments.
  """
  use Phoenix.Channel

  alias SmokerGadget.Pid.ControllerAgent
  alias SmokerGadgetWeb.PidControl

  def join("pid:control", _message, socket) do
    # send(self, {:output, 0.0})
    {:ok, socket}
  end

  def handle_in("setpoint_update", %{"setpoint" => setpoint}, socket) do
    # Should move the to_integer into the server so that it can
    # crash as an unhandled error and the server will be restarted
    # instead of this Channel being restarted
    :ok = ControllerAgent.update(setpoint: String.to_integer(setpoint))

    # push(socket, "setpoint_updated", %{setpoint: setpoint})

    {:noreply, socket}
  end

  def handle_in("kp_update", %{"kp" => kp}, socket) do
    :ok = ControllerAgent.update(kp: String.to_float(kp))

    {:noreply, socket}
  end

  def handle_in("ki_update", %{"ki" => ki}, socket) do
    :ok = ControllerAgent.update(ki: String.to_float(ki))

    {:noreply, socket}
  end

  def handle_in("kd_update", %{"kd" => kd}, socket) do
    :ok = ControllerAgent.update(kd: String.to_float(kd))

    {:noreply, socket}
  end

  def handle_in("start_controller", attrs, socket) do
    # I don't have a fancy web front-end framework to use for form
    # validation and I don't want to use the ol' alert box. So I'm
    # checking for an :error and setting the value to 0 or 0.0.
    setpoint =
      case Integer.parse(attrs["setpoint"]) do
        {float, _} -> float
        :error -> 0
      end

    kp =
      case Float.parse(attrs["kp"]) do
        {float, _} -> float
        :error -> 0.0
      end

    ki =
      case Float.parse(attrs["ki"]) do
        {float, _} -> float
        :error -> 0.0
      end

    kd =
      case Float.parse(attrs["kd"]) do
        {float, _} -> float
        :error -> 0.0
      end

    :ok = ControllerAgent.init(setpoint, kp, ki, kd)

    :ok = PidControl.start()

    {:noreply, socket}
  end

  def handle_in("stop_controller", _attrs, socket) do
    :ok = PidControl.stop()

    {:noreply, socket}
  end

  def handle_in("send_updates", {}, socket) do
    controller_state = ControllerAgent.get_state()

    push(socket, "controller_updated", %{
      input: controller_state.last_input,
      output: controller_state.last_output
    })

    {:noreply, socket}
  end
end
