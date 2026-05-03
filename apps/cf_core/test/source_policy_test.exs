defmodule CfCoreSourcePolicyTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)

  test "repo source avoids pattern engines and dynamic atom constructors" do
    hits =
      source_files()
      |> Enum.flat_map(&file_hits/1)

    assert hits == []
  end

  defp file_hits(path) do
    {:ok, body} = File.read(path)

    denied_tokens()
    |> Enum.filter(&String.contains?(body, &1))
    |> Enum.map(&"#{Path.relative_to(path, @repo_root)} contains #{inspect(&1)}")
  end

  defp source_files do
    [
      "mix.exs",
      "apps/*/mix.exs",
      "apps/*/lib/**/*.ex",
      "apps/*/test/**/*.ex",
      "apps/*/test/**/*.exs"
    ]
    |> Enum.flat_map(&Path.wildcard(Path.join(@repo_root, &1)))
    |> Enum.reject(&String.contains?(&1, "/deps/"))
    |> Enum.reject(&String.contains?(&1, "/_build/"))
    |> Enum.reject(&String.contains?(&1, "/doc/"))
    |> Enum.sort()
  end

  defp denied_tokens do
    pattern_engine_tokens() ++ dynamic_atom_tokens()
  end

  defp pattern_engine_tokens do
    [
      "Re" <> "gex",
      "~" <> "r",
      <<58>> <> "re" <> ".",
      "String" <> "." <> "match",
      "Reg" <> "Exp",
      "reg" <> "exp",
      "re" <> ".compile",
      "re" <> ".search",
      "re" <> ".match",
      "re" <> ".fullmatch",
      "re" <> ".sub",
      "re" <> ".split",
      "re" <> ".findall",
      "re" <> ".finditer",
      "from " <> "re" <> " import",
      "import " <> "re"
    ]
  end

  defp dynamic_atom_tokens do
    [
      "String" <> ".to_atom",
      "String" <> ".to_existing_atom",
      "binary" <> "_to_atom",
      "binary" <> "_to_existing_atom",
      "list" <> "_to_atom",
      "list" <> "_to_existing_atom",
      <<58>> <> "#" <> "{",
      <<58>> <> <<34>> <> "#" <> "{",
      <<58>> <> <<34>>
    ]
  end
end
