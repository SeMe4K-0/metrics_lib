defmodule MetricsLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics_lib,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "Лёгкая библиотека метрик для Elixir-приложений с LiveView-дашбордом",
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MetricsLib.Application, []}
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:phoenix_live_view, ">= 0.20.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix, ">= 1.7.0"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourname/metrics_lib"}
    ]
  end

  defp docs do
    [
      main: "MetricsLib",
      extras: ["README.md"]
    ]
  end
end
