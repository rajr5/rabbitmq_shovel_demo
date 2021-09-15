defmodule RabbitmqShovelDemoTest do
  use ExUnit.Case
  doctest RabbitmqShovelDemo

  test "greets the world" do
    assert RabbitmqShovelDemo.hello() == :world
  end
end
