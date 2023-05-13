defmodule DataTracer.MixProject do
  use Mix.Project

  @use_local_deps System.get_env("USE_LOCAL_DEPS") == "1" && File.exists?("local_deps.exs")

  def project do
    [
      app: :data_tracer,
      version: "0.1.0",
      description: description(),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      lockfile: if(@use_local_deps, do: "mix_local.lock", else: "mix.lock"),
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
      # {:matcha, "~> 0.1"},
      # Waiting for https://github.com/christhekeele/matcha/pull/47
      {:matcha, github: "christhekeele/matcha", branch: "latest"},
      # {:matcha, path: "~/dev/forks/matcha"},
      {:ex_doc, "~> 0.21", only: :docs},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false}
    ]
    |> Enum.concat(local_deps())
  end

  if @use_local_deps do
    defp local_deps do
      Code.require_file("local_deps.exs")
      DataTracer.LocalDeps.local_deps()
    end
  else
    defp local_deps, do: []
  end
end
