defmodule DataTracer.Server do
  use GenServer
  require Logger

  @moduledoc """
  Reads and writes the traced data to ETS

  Data format `{key, timestamp, value}`
  """

  @table_name :data_tracer

  defmodule State do
    defstruct [:table_name, :table]
  end

  @doc """
  Options:
  * `:table` - The ETS table to use for writing (optional)
  """
  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("DataTracer starting!")
    table_name = Keyword.get(opts, :table, @table_name)
    table = new(table_name)
    {:ok, %State{table_name: table_name, table: table}}
  end

  def all(opts \\ []) do
    table_name = Keyword.get(opts, :table, @table_name)

    :ets.match(table_name, {:"$1", :"$2", :"$3"})
    |> Enum.sort(fn [_, a, _], [_, b, _] ->
      case NaiveDateTime.compare(a, b) do
        :lt -> false
        :eq -> true
        :gt -> true
      end
    end)
  end

  def last(opts \\ []) do
    [_key, _timestamp, value] = all(opts) |> List.first()
    value
  end

  def store(value, opts \\ []) do
    key = Keyword.get(opts, :key)
    time = Keyword.get(opts, :time, NaiveDateTime.utc_now())
    table = Keyword.get(opts, :table, @table_name)

    if key do
      Logger.warn("Storing #{inspect(key)}:#{inspect(time)} => #{inspect(value, pretty: true)}")
    else
      Logger.warn("Storing #{inspect(time)} => #{inspect(value, pretty: true)}")
    end

    :ets.insert(table, {key, time, value})
    :ok
  end

  def lookup(key, opts \\ []) do
    table = Keyword.get(opts, :table, @table_name)

    :ets.lookup(table, key)
    |> Enum.map(fn {_, _, val} -> val end)
    |> case do
      [] -> nil
      val -> val
    end
  end

  def clear(name_or_pid \\ __MODULE__, _opts \\ []) do
    GenServer.call(name_or_pid, :clear)
  end

  @impl GenServer
  def handle_call(:clear, _from, state) do
    %State{table_name: table_name} = state
    :ets.delete(table_name)
    table = new(table_name)
    {:reply, :ok, %State{state | table: table}}
  end

  defp new(table_name) do
    :ets.new(table_name, [:duplicate_bag, :public, :named_table])
  end
end
