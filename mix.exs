defmodule DataTracer.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_tracer,
      version: "0.1.0",
      description: description(),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/axelson/data_tracer",
      homepage_url: "https://github.com/axelson/data_tracer"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DataTracer.Application, []},
      extra_applications: [:logger]
    ]
  end

  def description do
    """
    Elixir debug tool to facilitate inspection of data flow by capturing terms
    for inspection in IEx.
    """
  end

  def package do
    [
      name: :data_tracer,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Jason Axelson"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/axelson/data_tracer",
        "ChangeLog" => "https://github.com/axelson/data_tracer/blob/main/Changelog.md"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:machete, "~> 0.2.6", only: :test},
      # {:machete, path: "~/dev/forks/machete", only: :test},
      {:matcha, "~> 0.1"},
      # {:matcha, path: "~/dev/forks/matcha"},
      {:ex_doc, "~> 0.21", only: :docs},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end
end
