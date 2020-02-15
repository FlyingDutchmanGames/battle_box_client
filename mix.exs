defmodule BattleBoxClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :battle_box_client,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:gen_state_machine, "~> 2.0"}
    ]
  end
end
