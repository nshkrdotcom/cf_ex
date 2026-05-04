defmodule CfDurable.Object do
  @moduledoc """
  Provides a thin interface for accessing Durable Object namespaces
  """
  require Logger

  @spec get_namespace(String.t()) ::
          {:ok, any} | {:error, String.t()}
  def get_namespace(name) do
    case CfDurable.Runtime.call(:binding_get, [name]) do
      {:ok, namespace} when is_map(namespace) ->
        {:ok, namespace}

      {:error, reason} ->
        redacted_reason = CfDurable.Redaction.redact(reason, [name])

        Logger.error("Failed to resolve Durable Object namespace",
          reason: inspect(redacted_reason)
        )

        {:error, "Durable Object namespace not found: #{redacted_reason}"}

      _ ->
        {:error, "Unexpected response"}
    end
  end

  @spec get_namespace(String.t() | map(), keyword()) :: {:ok, any} | {:error, String.t()}
  def get_namespace(name_or_refs, opts) when is_list(opts) do
    if Keyword.has_key?(opts, :governed_authority) do
      governed_namespace(name_or_refs, nil, opts)
    else
      get_namespace(name_or_refs)
    end
  end

  @spec get_namespace(String.t(), String.t()) :: {:ok, any} | {:error, String.t()}
  def get_namespace(name, object_id) when is_binary(object_id),
    do: get_namespace("#{name}/#{object_id}")

  @spec get_namespace(String.t(), String.t(), keyword()) :: {:ok, any} | {:error, String.t()}
  def get_namespace(name, object_id, opts) when is_list(opts) do
    if Keyword.has_key?(opts, :governed_authority) do
      governed_namespace(name, object_id, opts)
    else
      get_namespace(name, object_id)
    end
  end

  defp governed_namespace(name_or_refs, object_id, opts) do
    case CfDurable.AuthorityGuard.validate_namespace(name_or_refs, object_id, opts) do
      {:ok, _refs} ->
        {:error, "Governed Durable Object binding not materialized in cf_ex"}

      {:error, error} ->
        {:error, error.message}
    end
  end
end
