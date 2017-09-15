defmodule Llixer.Mixfile do
  use Mix.Project


  def project do
    [
      app: :llixer,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [],
    ]
  end


  def application do
    [
      extra_applications: [
        :logger,
      ],
    ]
  end


  defp deps do
    [
      {:ex_spirit, "~> 0.3.3"},
      {:dialyxir, "~> 0.5.0", only: [:dev, :test], runtime: false},
      {:cortex, "~> 0.3.0", only: [:dev, :test]},
    ]
  end
end
