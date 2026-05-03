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
        Logger.error("Failed to resolve Durable Object namespace", reason: inspect(reason))
        {:error, "Durable Object namespace not found: #{reason}"}

      _ ->
        {:error, "Unexpected response"}
    end
  end

  @spec get_namespace(String.t(), String.t()) :: {:ok, any} | {:error, String.t()}
  def get_namespace(name, object_id), do: get_namespace("#{name}/#{object_id}")
end
