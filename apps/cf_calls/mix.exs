defmodule CfCalls.MixProject do
  use Mix.Project

  def project do
    [
      app: :cf_calls,
      version: "0.1.0",
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/nshkrdotcom/cf_ex/apps/cf_calls"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.18"},
      {:cf_core, in_umbrella: true},
      {:cf_durable, in_umbrella: true},
      {:stream_data, "~> 1.3", only: :test, runtime: false}
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
      licenses: ["MIT"],
      maintainers: ["nshkrdotcom"],
      links: %{"GitHub" => "https://github.com/nshkrdotcom/cf_ex/apps/cf_calls"}
    ]
  end
end
