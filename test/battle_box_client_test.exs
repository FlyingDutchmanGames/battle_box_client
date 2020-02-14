defmodule BattleBoxClientTest do
  use ExUnit.Case
  doctest BattleBoxClient

  test "greets the world" do
    assert BattleBoxClient.hello() == :world
  end
end
