defmodule CfDurable do
  @moduledoc """
  Provides helper functions for interacting with Cloudflare Durable Objects.
  """

  def hello, do: :world

  defmodule Storage do
    @moduledoc """
    Direct interface to DO storage
    """
    @spec put(String.t(), any()) :: {:ok, any()} | {:error, String.t()}
    def put(key, value) do
      case CfDurable.Runtime.call(:durable_object_storage_put, [key, value]) do
        :ok -> {:ok, value}
        {:error, reason} -> {:error, reason}
      end
    end

    @spec put(any(), String.t(), any()) :: {:ok, any()} | {:error, String.t()}
    def put(object, key, value) do
      case CfDurable.Runtime.call(:durable_object_storage_put, [object, key, value]) do
        :ok -> {:ok, value}
        {:error, reason} -> {:error, reason}
      end
    end

    @spec get(String.t()) :: {:ok, any()} | {:error, String.t()}
    def get(key) do
      case CfDurable.Runtime.call(:durable_object_storage_get, [key]) do
        {:ok, value} -> {:ok, value}
        {:error, reason} -> {:error, reason}
      end
    end

    @spec get(any(), String.t()) :: {:ok, any()} | {:error, String.t()}
    def get(object, key), do: CfDurable.Runtime.call(:durable_object_storage_get, [object, key])

    @spec list(String.t()) :: {:ok, list(map())} | {:error, String.t()}
    def list(prefix) do
      case CfDurable.Runtime.call(:durable_object_storage_list, [prefix]) do
        {:ok, map} -> {:ok, map}
        {:error, reason} -> {:error, reason}
      end
    end

    @spec delete(String.t()) :: :ok | {:error, String.t()}
    def delete(key) do
      case CfDurable.Runtime.call(:durable_object_storage_delete, [key]) do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    end

    @spec delete(any(), String.t()) :: :ok | {:error, String.t()}
    def delete(object, key),
      do: CfDurable.Runtime.call(:durable_object_storage_delete, [object, key])
  end
end
