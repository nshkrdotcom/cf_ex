defmodule CfEx.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Include support files
      test_paths: ["test/support", "apps/*/test"],
      preferred_cli_env: [
        test: :test,
        "test.coverage": :test
      ],
      extra_applications: [:logger, :observer]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:stream_data, "~> 0.7", only: :test}
    ]
  end
end
