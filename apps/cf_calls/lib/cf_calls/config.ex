defmodule CfCalls.Config do
  @moduledoc """
  Configuration for Cloudflare Calls API.
  """

  @type t :: %__MODULE__{
    app_id: String.t(),
    app_token: String.t()
  }

  defstruct [:app_id, :app_token]

  @doc """
  Creates a new config struct.
  """
  @spec new(String.t(), String.t()) :: t()
  def new(app_id, app_token) do
    %__MODULE__{
      app_id: app_id,
      app_token: app_token
    }
  end
end
