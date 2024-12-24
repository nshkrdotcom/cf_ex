defmodule ExCloudflareCalls.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cloudflare_calls,
      version: "0.1.0",
      elixir: "~> 1.17",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/nshkrdotcom/ex_cloudflare_calls"
      #,homepage_url: "TODO:"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExCloudflareCalls.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      #{:ex_cloudflare_core, path: "../ex_cloudflare_core"},
    ]
  end

  defp description() do
    "Provides comprehensive stateful integration with Cloudflare Calls API."
  end

  defp package() do
    [
      name: "Cloudflare Calls",
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      maintainers: ["nshkrdotcom"],
      #description: "Provides comprehensive stateful integration with Cloudflare Calls API.",
      links: %{"GitHub" => "https://github.com/nshkrdotcom/ex_cloudflare_calls"}
    ]
  end

end
