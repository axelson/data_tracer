defmodule DataTracer do
  @moduledoc """
  Facilitates debugging by holding data traces of interesting data. Is a
  GenServer so it can own an ets table to store the data in.
  """

  use GenServer
  require Logger

  @table_name :data_tracer

  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    Logger.debug("DataTracer starting!")
    table = :ets.new(@table_name, [:set, :protected, :named_table])
    {:ok, table}
  end

  def all do
    :ets.match(@table_name, {:"$1", :"$2"})
    |> Enum.sort(fn [a, _], [b, _] ->
      case NaiveDateTime.compare(a, b) do
        :lt -> false
        :eq -> true
        :gt -> true
      end
    end)
  end

  def last do
    [_time, entry] = all() |> Enum.at(0)
    entry
  end

  def store(value) do
    key = NaiveDateTime.utc_now()
    GenServer.call(__MODULE__, {:store_key, key, value})
  end

  def store_key(key, value) do
    GenServer.call(__MODULE__, {:store_key, key, value})
  end

  def lookup(key) do
    case :ets.lookup(@table_name, key) do
      [] -> nil
      [{^key, val}] -> val
    end
  end

  def clear do
    pid = Process.whereis(__MODULE__)
    Process.exit(pid, :kill)
  end

  def handle_call({:store_key, key, value}, _from, table) do
    Logger.warn("Storing #{inspect(key)} => #{inspect(value, pretty: true)}")
    :ets.insert(table, {key, value})
    {:reply, :ok, table}
  end
end
