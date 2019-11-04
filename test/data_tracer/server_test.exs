defmodule DataTracer.ServerTest do
  use ExUnit.Case, async: true

  setup do
    table_name = :data_tracer_test
    {:ok, tracer} = DataTracer.Server.start_link([table: table_name], nil)
    %{table_name: table_name, tracer: tracer}
  end

  test "store multiple values and retrieves them", %{table_name: table_name, tracer: tracer} do
    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("abc", tracer: tracer)
      DataTracer.store("cde", tracer: tracer)
      DataTracer.store("fgh", tracer: tracer)

      assert [
               [nil, _, "fgh"],
               [nil, _, "cde"],
               [nil, _, "abc"]
             ] = DataTracer.all(table: table_name)
    end)
  end

  test "store a value by key and look it up", %{table_name: table_name, tracer: tracer} do
    DataTracer.store("42", key: "the_answer", tracer: tracer)

    assert DataTracer.lookup("the_answer", table: table_name) == ["42"]
  end

  test "lookup multiple values under the same key", %{table_name: table_name, tracer: tracer} do
    DataTracer.store("100", key: "age", tracer: tracer)
    DataTracer.store("101", key: "age", tracer: tracer)

    assert DataTracer.lookup("age", table: table_name) == ["100", "101"]
  end

  test "retrieves values based on timestamp", %{table_name: table_name, tracer: tracer} do
    t1 = ~N[2019-01-01 00:00:00]
    t2 = ~N[2019-01-02 00:00:00]
    t3 = ~N[2019-01-03 00:00:00]

    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("1", time: t3, tracer: tracer)
      DataTracer.store("2", time: t1, tracer: tracer)
      DataTracer.store("3", time: t2, tracer: tracer)

      assert [
               [nil, _, "1"],
               [nil, _, "3"],
               [nil, _, "2"]
             ] = DataTracer.all(table: table_name)
    end)
  end

  test "clear clears the table", %{table_name: table_name, tracer: tracer} do
    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("42", key: "the_answer", tracer: tracer)

      assert DataTracer.lookup("the_answer", table: table_name) == ["42"]

      DataTracer.clear(tracer: tracer)

      assert DataTracer.all(table: table_name) == []

      DataTracer.store("a", tracer: tracer)

      assert [[_, _, "a"]] = DataTracer.all(table: table_name)
    end)
  end

  test "lookup/1 when key does not exist", %{table_name: table_name} do
    assert DataTracer.lookup("bogus", table: table_name) == nil
  end
end
