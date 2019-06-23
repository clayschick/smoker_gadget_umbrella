defmodule SmokerGadget.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  @target_env System.get_env("MIX_ENV") || "test"

  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :bbb, :x86_64]

  def project do
    [
      app: :smoker_gadget,
      version: "0.1.0",
      target: @target,
      target_env: @target_env,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      build_embedded: @target != "host",
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {SmokerGadget.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.

  # Dependencies for all targets
  defp deps do
    [
      {:nerves, "~> 1.3", only: [:dev, :prod], runtime: false},
      {:shoehorn, "~> 0.4"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},
      {:timex, "~> 3.5"},
      # {:circuits_spi, "~> 0.1"},
      # {:pigpiox, "~> 0.1"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host") do
    [
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Dependencies for all targets except :host
  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.6"},
      {:nerves_init_gadget, "~> 0.4"},
      {:circuits_spi, "~> 0.1"},
      {:pigpiox, "~> 0.1"}
    ] ++ system(target)
  end

  defp system("rpi"), do: [{:nerves_system_rpi, "~> 1.5", runtime: false}]
  defp system("rpi0"), do: [{:nerves_system_rpi0, "~> 1.5", runtime: false}]
  defp system("rpi2"), do: [{:nerves_system_rpi2, "~> 1.5", runtime: false}]
  defp system("rpi3"), do: [{:nerves_system_rpi3, "~> 1.5", runtime: false}]
  defp system("bbb"), do: [{:nerves_system_bbb, "~> 2.0", runtime: false}]
  defp system("x86_64"), do: [{:nerves_system_x86_64, "~> 1.5", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")

  # defp deps do
  #   [
  #     # Dependencies for all targets
  #     {:nerves, "~> 1.4", runtime: false},
  #     {:shoehorn, "~> 0.4"},
  #     {:ring_logger, "~> 0.6"},
  #     {:toolshed, "~> 0.2"},
  #     {:timex, "~> 3.5"},

  #     # Dependencies for all targets except :host
  #     {:nerves_runtime, "~> 0.6", targets: @all_targets},
  #     {:nerves_init_gadget, "~> 0.4", targets: @all_targets},

  #     # Dependencies for specific targets
  #     {:nerves_system_rpi, "~> 1.6", runtime: false, targets: :rpi},
  #     {:nerves_system_rpi0, "~> 1.6", runtime: false, targets: :rpi0},
  #     {:nerves_system_rpi2, "~> 1.6", runtime: false, targets: :rpi2},
  #     {:nerves_system_rpi3, "~> 1.6", runtime: false, targets: :rpi3},
  #     {:nerves_system_rpi3a, "~> 1.6", runtime: false, targets: :rpi3a},
  #     {:nerves_system_bbb, "~> 2.0", runtime: false, targets: :bbb},
  #     {:nerves_system_x86_64, "~> 1.6", runtime: false, targets: :x86_64},
  #   ]
  # end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [loadconfig: [&bootstrap/1]]
  end
end
