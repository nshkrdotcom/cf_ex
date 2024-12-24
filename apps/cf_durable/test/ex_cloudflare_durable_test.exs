defmodule ExCloudflareDurableTest do
  use ExUnit.Case
  doctest ExCloudflareDurable

  test "greets the world" do
    assert ExCloudflareDurable.hello() == :world
  end
end
