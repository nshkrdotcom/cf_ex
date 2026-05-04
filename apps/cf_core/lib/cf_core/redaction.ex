defmodule CfCore.Redaction do
  @moduledoc """
  Deterministic fixed-literal redaction helpers for Cloudflare receipts.
  """

  @marker "[REDACTED]"

  @spec redact(term(), [String.t()]) :: term()
  def redact(value, protected_values \\ []) do
    protected_values =
      protected_values
      |> List.wrap()
      |> Enum.filter(&is_binary/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    do_redact(value, protected_values)
  end

  defp do_redact(value, protected_values) when is_binary(value) do
    Enum.reduce(protected_values, value, fn protected_value, acc ->
      String.replace(acc, protected_value, @marker)
    end)
  end

  defp do_redact(value, protected_values) when is_list(value) do
    Enum.map(value, &do_redact(&1, protected_values))
  end

  defp do_redact(value, protected_values) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> do_redact(protected_values)
    |> List.to_tuple()
  end

  defp do_redact(value, protected_values) when is_map(value) do
    Map.new(value, fn {key, map_value} ->
      {do_redact(key, protected_values), do_redact(map_value, protected_values)}
    end)
  end

  defp do_redact(value, _protected_values), do: value
end
