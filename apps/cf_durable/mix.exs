defmodule CfDurable.MixProject do
  use Mix.Project

  def project do
    [
      app: :cf_durable,
      version: "0.1.0",
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/nshkrdotcom/cf_ex/apps/cf_durable"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 1.3", only: :test, runtime: false}
    ]
  end

  defp description() do
    "Provides comprehensive stateful integration with Cloudflare Durable Objects."
  end

  defp package() do
    [
      name: "Cloudflare Durable Objects",
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["MIT"],
      maintainers: ["nshkrdotcom"],
      links: %{"GitHub" => "https://github.com/nshkrdotcom/cf_ex/apps/cf_durable"}
    ]
  end
end
