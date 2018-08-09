defmodule RabbitUtilsTest do
  use ExUnit.Case
  doctest RabbitUtils

  test "greets the world" do
    assert RabbitUtils.hello() == :world
  end
end
