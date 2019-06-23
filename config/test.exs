use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :smoker_gadget_web, SmokerGadgetWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :smoker_gadget, Fw.Temperature,
  spi_adapter: SmokerGadget.Fw.Adapters.SpiTest

config :smoker_gadget, Fw.Fan,
  pwm_adapter: SmokerGadget.Fw.Adapters.PwmTest,
  pwm_pin: 18,
  pwm_frequency: 25_000,
  pwm_frequency_multiplier: 1
