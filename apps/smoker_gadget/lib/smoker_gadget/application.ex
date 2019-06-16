defmodule SmokerGadget.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SmokerGadget.Fw

  @target Mix.Project.config()[:target]
  @target_env Mix.Project.config()[:target_env]

  def start(_type, _args) do
    stop_fan(@target_env)

    children = [
      # SmokerGadget.Worker
      SmokerGadget.Pid.ControllerAgent
    ] ++ children(@target)

    Supervisor.start_link(children, strategy: :one_for_one, name: SmokerGadget.Supervisor)
  end

  def children("host") do
    [
      Fw.Adapters.SpiTest,
      Fw.Temperature
    ]
  end

  def children(_target) do
    [
      Fw.Temperature
    ]
  end

  # PWM fans run when there is no voltage on the PWM pin
  # Need to stop the running fan when the app starts
  defp stop_fan("prod"), do: Fw.Fan.stop

  defp stop_fan(_), do: :ok
end
