defmodule SmokerGadgetWeb.PidControlAgent do
  @moduledoc """
  Used to hold the `auto` status of the controller.
  """

  use Agent

  @spec start_link(any, any) :: {:error, any} | {:ok, pid}
  def start_link(_args, _option_list \\ []),
    do: Agent.start_link(fn -> false end, name: __MODULE__)

  @spec is_auto? :: boolean
  def is_auto?(), do: Agent.get(__MODULE__, & &1)

  @spec set_auto(boolean) :: :ok
  def set_auto(val), do: Agent.update(__MODULE__, fn _ -> val end)
end
