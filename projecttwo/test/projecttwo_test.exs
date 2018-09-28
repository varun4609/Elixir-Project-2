defmodule ProjecttwoTest do
  use ExUnit.Case
  doctest Projecttwo

  test "greets the world" do
    assert Projecttwo.hello() == :world
  end
end
