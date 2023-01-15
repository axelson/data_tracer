defmodule DataTracer.ServerTest do
  use ExUnit.Case, async: true

  setup do
    table_name = :data_tracer_test
    {:ok, tracer} = DataTracer.Server.start_link([table: table_name], nil)
    %{table: table_name, tracer: tracer}
  end

  test "store multiple values and retrieves them", %{table: table} do
    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("abc", table: table)
      DataTracer.store("cde", table: table)
      DataTracer.store("fgh", table: table)

      assert [
               [nil, _, "fgh"],
               [nil, _, "cde"],
               [nil, _, "abc"]
             ] = DataTracer.all(table: table)
    end)
  end

  test "store a value by key and look it up", %{table: table} do
    DataTracer.store("42", key: "the_answer", table: table)

    assert DataTracer.lookup("the_answer", table: table) == ["42"]
  end

  test "lookup multiple values under the same key", %{table: table} do
    DataTracer.store("100", key: "age", table: table)
    DataTracer.store("101", key: "age", table: table)

    assert DataTracer.lookup("age", table: table) == ["100", "101"]
  end

  test "retrieves values based on timestamp", %{table: table} do
    t1 = ~N[2019-01-01 00:00:00]
    t2 = ~N[2019-01-02 00:00:00]
    t3 = ~N[2019-01-03 00:00:00]

    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("1", time: t3, table: table)
      DataTracer.store("2", time: t1, table: table)
      DataTracer.store("3", time: t2, table: table)

      assert [
               [nil, _, "1"],
               [nil, _, "3"],
               [nil, _, "2"]
             ] = DataTracer.all(table: table)
    end)
  end

  test "clear clears the table", %{table: table, tracer: tracer} do
    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("42", key: "the_answer", table: table)

      assert DataTracer.lookup("the_answer", table: table) == ["42"]

      DataTracer.clear(tracer)

      assert DataTracer.all(table: table) == []

      DataTracer.store("a", table: table)

      assert [[_, _, "a"]] = DataTracer.all(table: table)
    end)
  end

  test "lookup/1 when key does not exist", %{table: table} do
    assert DataTracer.lookup("bogus", table: table) == nil
  end
end
