defmodule CfCoreTest do
  use ExUnit.Case
  doctest CfCore

  test "greets the world" do
    assert CfCore.hello() == :world
  end
end
