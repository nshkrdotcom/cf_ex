defmodule CfCalls.Config do
  @moduledoc """
  Configuration for Cloudflare Calls API.
  """

  @type t :: %__MODULE__{
          app_id: String.t(),
          app_token: String.t(),
          governed_authority: map() | keyword() | nil,
          redaction_values: [String.t()]
        }

  defstruct [:app_id, :app_token, :governed_authority, redaction_values: []]

  @doc """
  Creates a new config struct.
  """
  @spec new(String.t(), String.t(), keyword()) :: t()
  def new(app_id, app_token, opts \\ []) do
    %__MODULE__{
      app_id: app_id,
      app_token: app_token,
      governed_authority: Keyword.get(opts, :governed_authority),
      redaction_values: Keyword.get(opts, :redaction_values, [])
    }
  end
end
