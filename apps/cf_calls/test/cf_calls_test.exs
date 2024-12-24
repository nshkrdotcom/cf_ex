defmodule CfCallsTest do
  use ExUnit.Case
  doctest CfCalls

  test "greets the world" do
    assert CfCalls.hello() == :world
  end
end
