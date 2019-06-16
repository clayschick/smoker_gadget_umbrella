defmodule SmokerGadget.Pid.Controller do
  @moduledoc """
  PID Controller Implementation
  """

  require Logger

  alias SmokerGadget.Fw
  alias SmokerGadget.Pid.ControllerAgent

  @doc """
  The controller function that evaluates an output value to be applied to
  something that will adjust the input.

  What should the sample rate be and how can I make it consistent?
  - the MAX31865 needs at least 65 milliseconds because it has a frequency
    at which it will cycle through a read or write
  """
  @spec evaluate(float) :: float
  def evaluate(input) do
    state = ControllerAgent.get_state()
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    time_delta = now - state.last_time

    error = state.setpoint - input

    Logger.debug("Error: #{error}")

    # accumulation_of_error = state.accumulation_of_error + error * time_delta

    integral = state.i_term + state.ki * error

    derivative_of_input = (input - state.last_input) / time_delta

    # output = state.kp * error + state.ki * accumulation_of_error - state.kd * derivative_of_input
    output = state.kp * error + integral - state.kd * derivative_of_input

    Logger.debug("PID Output: #{output}")

    :ok =
      ControllerAgent.update(
        # accumulation_of_error: accumulation_of_error,
        last_input: input,
        last_output: output,
        last_time: now,
        i_term: integral
      )

    output
  end

  @doc """
  Use these functions to handle adapter config stuff and other things
  specific to reading and adjusting the side-effecty things
  """
  @spec read :: float
  def read, do: Fw.Temperature.read()

  @spec adjust(number) :: :ok | {:error, any}
  def adjust(output), do: Fw.Fan.adjust(output)

  @doc """
  With statement used as an implementation of the
  read/evaluate/adjust cycle. Returns the input and
  output together to be consumed by the UI.
  """
  @spec cycle :: {:ok, %{input: float, output: float}} | String.t
  def cycle do
    with {:read, input} <- {:read, read()},
         {:evaluate, output} <- {:evaluate, evaluate(input)},
         {:adjust, :ok} <- {:adjust, adjust(output)},
         _ <- :timer.sleep(500) do
      {:ok, %{input: input, output: output}}
    else
      # Can pattern match on the error to be more specific
      {:read, msg} -> "Error while reading input - #{msg}" |> Logger.error
      {:evaluate, msg} -> "Error while evaluating - #{msg}" |> Logger.error
      {:adjust, msg} -> "Error while adjusting - #{msg}" |> Logger.error
    end
  end
end
