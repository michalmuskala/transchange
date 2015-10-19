defmodule Transchange.Mixfile do
  use Mix.Project

  def project do
    [app: :transchange,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :ecto]]
  end

  defp deps do
    [{:ecto, "~> 1.0"}]
  end
end
