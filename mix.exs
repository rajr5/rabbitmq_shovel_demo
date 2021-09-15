defmodule RMQDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :rmq_demo,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_rmq, "~> 3.0.0"},
      {:amqp, "2.1.2", override: true},
      {:jason, "1.2.2"}
    ]
  end
end
