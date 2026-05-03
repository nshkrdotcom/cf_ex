defmodule CfEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/nshkrdotcom/cf_ex"

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      extra_applications: [:logger, :observer]
    ]
  end

  def cli do
    [
      preferred_envs: [
        test: :test,
        "test.coverage": :test
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
