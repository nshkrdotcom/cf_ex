defmodule CfCalls.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc """
  Application for CfCalls.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: CfCalls.Worker.start_link(arg)
      # {CfCalls.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CfCalls.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
