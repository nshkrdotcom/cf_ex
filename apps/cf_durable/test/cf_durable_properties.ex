defmodule CfDurableTest.Properties do
  use ExUnit.Case
  import StreamData
  import CfEx.StreamData

  property "Storage.put/get round trip on valid keys" do
    check all key <- string(:alphanumeric, min_length: 5, max_length: 20),
    value <- any()  do
      with {:ok, stored_value} <- CfDurable.Storage.put(key, value),
      {:ok, retrieved_value} <- CfDurable.Storage.get(key) do
        assert stored_value == retrieved_value
      else
        _ ->
          false
      end
    end
  end

 property "Storage.delete removes the value" do
    check all key <- string(:alphanumeric, min_length: 5, max_length: 20),
    value <- any()  do
      with {:ok, _} <- CfDurable.Storage.put(key, value),
        :ok <- CfDurable.Storage.delete(key),
        {:error, _} <- CfDurable.Storage.get(key)
      do
        true
      else
        _ ->
          false
      end
    end
  end


  property "Storage.list with a valid prefix" do
    check all prefix <- string(:alphanumeric, min_length: 2, max_length: 5) do
    with {:ok, results} <- CfDurable.Storage.list(prefix) do
      case results do
        [] -> true
      list when is_list(list) -> true
        _ -> false
      end
      else
        _ -> false
      end
    end
  end


  property "Object.get_namespace returns an error on invalid names" do
    check all name <- string(:ascii, min_length: 1, max_length: 20),
    name =  String.downcase(name) do
      refute CfDurable.Object.get_namespace(name) == {:ok, _}
    end
  end
end
