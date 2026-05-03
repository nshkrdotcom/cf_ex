defmodule CfDurable.Runtime do
  @moduledoc false

  def call(function, args) when is_atom(function) and is_list(args) do
    apply(:cloudflare, function, args)
  rescue
    UndefinedFunctionError -> {:error, "Cloudflare runtime unavailable"}
  end
end
