defmodule ExCloudflareCoreTest do
  use ExUnit.Case
  doctest ExCloudflareCore

  test "greets the world" do
    assert ExCloudflareCore.hello() == :world
  end
end
