defmodule CfDurable.Runtime do
  @moduledoc false

  def call(function, args) when is_atom(function) and is_list(args) do
    with {:ok, _event_kind} <- CfDurable.RuntimePolicy.runtime_event_kind_for_function(function) do
      apply(:cloudflare, function, args)
    else
      {:error, {:unknown_runtime_function, _function}} ->
        {:error, "Unknown Cloudflare runtime function"}
    end
  rescue
    UndefinedFunctionError -> {:error, "Cloudflare runtime unavailable"}
  end
end
