defmodule SmokerGadget.Fw.Adapters.SpiBehaviour do
  @moduledoc """
  Specification for SPI behaviour
  """
  @callback open(device :: String.t, options :: charlist) :: {:ok, reference}

  @callback transfer(ref :: reference, data :: binary) :: {:ok, binary}
end
