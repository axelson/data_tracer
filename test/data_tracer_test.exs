defmodule DataTracerTest do
  use ExUnit.Case
  doctest DataTracer

  test "greets the world" do
    assert DataTracer.hello() == :world
  end
end
