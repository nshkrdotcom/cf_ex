defmodule CfCalls.Error do
  @moduledoc """
  Error handling for Cloudflare Calls API.
  """

  @type t :: %__MODULE__{
    status_code: integer() | nil,
    error: String.t(),
    details: map() | nil
  }

  defstruct [:status_code, :error, :details]

  @doc """
  Creates a new error struct.
  """
  def new(error, opts \\ []) do
    %__MODULE__{
      status_code: Keyword.get(opts, :status_code),
      error: error,
      details: Keyword.get(opts, :details)
    }
  end
end
