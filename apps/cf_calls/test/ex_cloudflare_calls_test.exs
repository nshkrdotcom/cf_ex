defmodule ExCloudflareCallsTest do
  use ExUnit.Case
  doctest ExCloudflareCalls

  test "greets the world" do
    assert ExCloudflareCalls.hello() == :world
  end
end
