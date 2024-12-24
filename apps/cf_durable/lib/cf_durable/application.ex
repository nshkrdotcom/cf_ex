defmodule CfDurable.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc "Application for CfDurable."

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ExCloudflareDurable.Worker.start_link(arg)
      # {ExCloudflareDurable.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CfDurable.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
