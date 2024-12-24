defmodule CfDurableTest do
  use ExUnit.Case
  doctest CfDurable

  test "greets the world" do
    assert CfDurable.hello() == :world
  end
end
