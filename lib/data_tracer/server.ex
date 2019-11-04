defmodule DataTracer.Server do
  use GenServer
  require Logger

  @table_name :data_tracer

  defmodule State do
    defstruct [:table_name, :table]
  end

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
    [_time, entry] = all(opts) |> Enum.at(0)
    entry
  end

  def store(value, opts \\ []) do
    time = Keyword.get(opts, :time, NaiveDateTime.utc_now())
    key = Keyword.get(opts, :key)
    tracer = Keyword.get(opts, :tracer)

    GenServer.call(tracer, {:store_key, key, time, value})
    value
  end

  def lookup(key, opts \\ []) do
    table_name = Keyword.get(opts, :table, @table_name)

    :ets.lookup(table_name, key)
    |> Enum.map(fn {_, _, val} -> val end)
    |> case do
      [] -> nil
      val -> val
    end
  end

  def clear(opts \\ []) do
    tracer = Keyword.get(opts, :tracer)

    GenServer.call(tracer, :clear)
  end

  @impl GenServer
  def handle_call({:store_key, key, time, value}, _from, state) do
    %State{table: table} = state

    if key do
      Logger.warn("Storing #{inspect(key)}:#{inspect(time)} => #{inspect(value, pretty: true)}")
    else
      Logger.warn("Storing #{inspect(time)} => #{inspect(value, pretty: true)}")
    end

    :ets.insert(table, {key, time, value})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    %State{table_name: table_name} = state
    :ets.delete(table_name)
    table = new(table_name)
    {:reply, :ok, %State{state | table: table}}
  end

  defp new(table_name) do
    :ets.new(table_name, [:duplicate_bag, :protected, :named_table])
  end
end
