defmodule SmokerGadget.Fw.Adapters.SpiTest do
  @moduledoc false

  use Agent

  @behaviour SmokerGadget.Fw.Adapters.SpiBehaviour

  @spec start_link(list) :: {:error, any} | {:ok, pid}
  def start_link(_args \\ []) do
    # This is 72.17413285784122 degrees
    Agent.start_link(fn -> 8283 end, name: __MODULE__)
  end

  @impl true
  @spec open(any, any) :: {:ok, reference}
  def open(_device, _options) do
    {:ok, :erlang.make_ref()}
  end

  @impl true
  @spec transfer(any, any) :: {:ok, <<_::24>>}
  def transfer(_ref, _data) do
    rtd_value = Agent.get(__MODULE__, &trunc(&1))

    {:ok, <<0::size(8), rtd_value::size(15), 0::size(1)>>}
  end

  @spec fake_temp_adjustment(number) :: :ok
  def fake_temp_adjustment(pid_output) do
    Agent.update(__MODULE__, fn state -> state + pid_output end)
  end
end
