defmodule SmokerGadgetWeb.PidControl do
  @moduledoc """
  Starts and stops the Tasks that will run the controller
  and the update to the UI.
  """

  alias SmokerGadget.Pid.Controller
  alias SmokerGadgetWeb.PidControlAgent

  @doc """
  Stops the controller and ui update task by setting the
  Ui.Agent.auto to false.
  """
  @spec stop :: :ok
  def stop, do: PidControlAgent.set_auto(false)

  @doc """
  Starts a Task that will update the UI.

  Sets the UI auto state to true.
  """
  @spec start :: :ok
  def start do
    :ok = PidControlAgent.set_auto(true)

    {:ok, _} = Task.start(fn -> ui_loop(true) end)

    :ok
  end

  @doc """
  Cycles the controller and broadcasts the results to the UI.

  Runs recursively in a Task until a `false` boollean type is
  matched in the function definition. The `:ok` returned will
  end the Task.
  """
  @spec ui_loop(boolean) :: :ok
  def ui_loop(true) do
    Controller.cycle() |> broadcast_to_ui()

    ui_loop(PidControlAgent.is_auto?())
  end

  def ui_loop(false), do: :ok

  defp broadcast_to_ui({:ok, %{input: input, output: output}}) do
    SmokerGadgetWeb.Endpoint.broadcast("pid:control", "controller_updated", %{
      input: input,
      output: output
    })
  end
end
