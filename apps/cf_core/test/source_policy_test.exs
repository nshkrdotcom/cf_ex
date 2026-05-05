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
    @repo_root
    |> list_files()
    |> Enum.filter(&source_path?/1)
    |> Enum.sort()
  end

  defp list_files(root) do
    root
    |> File.ls!()
    |> Enum.flat_map(fn entry ->
      path = Path.join(root, entry)

      cond do
        excluded_path?(path) -> []
        File.dir?(path) -> list_files(path)
        File.regular?(path) -> [path]
        true -> []
      end
    end)
  end

  defp source_path?(path) do
    relative = Path.relative_to(path, @repo_root)

    relative == "mix.exs" or
      (String.starts_with?(relative, "apps/") and String.ends_with?(relative, "/mix.exs")) or
      (String.starts_with?(relative, "apps/") and String.contains?(relative, "/lib/") and
         String.ends_with?(relative, ".ex")) or
      (String.starts_with?(relative, "apps/") and String.contains?(relative, "/test/") and
         (String.ends_with?(relative, ".ex") or String.ends_with?(relative, ".exs")))
  end

  defp excluded_path?(path) do
    relative = Path.relative_to(path, @repo_root)

    String.starts_with?(relative, "deps/") or
      String.contains?(relative, "/deps/") or
      String.ends_with?(relative, "/deps") or
      String.starts_with?(relative, "_build/") or
      String.contains?(relative, "/_build/") or
      String.ends_with?(relative, "/_build") or
      String.starts_with?(relative, "doc/") or
      String.contains?(relative, "/doc/") or
      String.ends_with?(relative, "/doc")
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
      "import " <> "re",
      "Path" <> "." <> "wildcard"
    ]
  end

  defp dynamic_atom_tokens do
    [
      "String" <> ".to_" <> "atom",
      "String" <> ".to_" <> "existing_" <> "atom",
      "binary" <> "_to_" <> "atom",
      "binary" <> "_to_" <> "existing_" <> "atom",
      "list" <> "_to_" <> "atom",
      "list" <> "_to_" <> "existing_" <> "atom",
      "Module" <> "." <> "concat",
      <<58>> <> "#" <> "{",
      <<58>> <> <<34>> <> "#" <> "{",
      <<58>> <> <<34>>
    ]
  end
end
