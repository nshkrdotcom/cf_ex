defmodule ExCloudflareDurable.Object do
  @moduledoc """
  Provides a thin interface for accessing Durable Object namespaces
  """
  require Logger

    @spec get_namespace(String.t()) ::
             {:ok, any} | {:error, String.t()}
  def get_namespace(name) do
    case :cloudflare.binding_get(name) do
      {:ok, namespace} when is_map(namespace) ->
          {:ok, namespace}
      {:error, reason} ->
          Logger.error("Failed to resolve Durable Object Namespace with name: #{name} - #{reason}")
           {:error, "Durable Object Namespace with name: #{name} not found: #{reason}"}
          _ ->
              {:error, "Unexpected response"}
       end
  end
end
