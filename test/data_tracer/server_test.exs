defmodule DataTracer.ServerTest do
  use ExUnit.Case, async: true
  use Machete

  setup do
    table_name = :data_tracer_test
    {:ok, tracer} = DataTracer.Server.start_link([table: table_name], nil)
    %{table: table_name, tracer: tracer}
  end

  test "store multiple values and retrieves them in reverse order", %{table: table} do
    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("abc", table: table)
      Process.sleep(1)
      DataTracer.store("cde", table: table)
      Process.sleep(1)
      DataTracer.store("fgh", table: table)

      assert [
               {_, nil, "fgh"},
               {_, nil, "cde"},
               {_, nil, "abc"}
             ] = DataTracer.all(table: table)
    end)
  end

  test "store a value by key and look it up", %{table: table} do
    assert DataTracer.store("42", key: "the_answer", table: table) == "42"

    assert DataTracer.lookup("the_answer", table: table) == ["42"]
  end

  test "store_uniq/1 stores a single value" do
    assert DataTracer.store_uniq("first") == "first"
    assert DataTracer.store_uniq("second") == "second"

    assert DataTracer.all() ~> [{unix_time(roughly: :now), nil, "second"}]
  end

  test "store_uniq can store one value", %{table: table} do
    DataTracer.store_uniq("a", table: table)

    assert DataTracer.lookup(nil, table: table) == ["a"]
  end

  test "store_uniq replaces the keys if they already exist", %{table: table} do
    DataTracer.store_uniq("a", key: "the_answer", table: table)
    DataTracer.store_uniq("b", key: "the_answer", table: table)
    DataTracer.store_uniq("c", key: "the_answer", table: table)

    assert DataTracer.lookup("the_answer", table: table) == ["c"]
    assert [{_, _dup_key, "c"}] = DataTracer.all(table: table)
  end

  test "store_uniq uses the current time", %{table: table} do
    DataTracer.store_uniq("uniq", table: table)

    key = nil
    assert DataTracer.all(table: table) ~> [{unix_time(roughly: :now), key, "uniq"}]
  end

  test "lookup multiple values under the same key", %{table: table} do
    DataTracer.store("100", key: "age", table: table)
    DataTracer.store("101", key: "age", table: table)

    assert DataTracer.lookup("age", table: table) == ["101", "100"]
  end

  test "retrieves values based on timestamp", %{table: table} do
    t1 = 1_673_805_804_091
    t2 = t1 + 1
    t3 = t1 + 2

    ExUnit.CaptureLog.capture_log(fn ->
      DataTracer.store("1", time: t3, table: table)
      DataTracer.store("2", time: t1, table: table)
      DataTracer.store("3", time: t2, table: table)

      assert [
               {^t3, nil, "1"},
               {^t2, nil, "3"},
               {^t1, nil, "2"}
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

      assert [{_, _, "a"}] = DataTracer.all(table: table)
    end)
  end

  test "lookup/1 when key does not exist", %{table: table} do
    assert DataTracer.lookup("bogus", table: table) == []
  end

  test "last/1 when there are no values returns an :data_tracer_table_is_empty", %{table: table} do
    assert DataTracer.last(table: table) == :data_tracer_table_is_empty
  end

  test "last/1 when there is one value returns the value", %{table: table} do
    DataTracer.store("value1", table: table)
    assert DataTracer.last(table: table) == "value1"
  end

  test "last/1 when there are multiple values with different timestamps returns the latest value",
       %{table: table} do
    DataTracer.store("value1", table: table)
    Process.sleep(1)
    DataTracer.store("value2", table: table)

    assert DataTracer.last(table: table) == "value2"
  end

  test "last/1 when there are multiple values with the same timestamps returns the latest value",
       %{table: table} do
    t1 = 1_673_805_804_091
    t2 = t1 + 1
    t3 = t1 + 2

    DataTracer.store("t3", time: t3, table: table)
    DataTracer.store("t2", time: t1, table: table)
    DataTracer.store("t3_b", time: t3, table: table)
    DataTracer.store("t2", time: t2, table: table)

    assert DataTracer.last(table: table) == "t3_b"
  end
end
