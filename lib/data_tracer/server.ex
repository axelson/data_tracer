defmodule DataTracer.Server do
  use GenServer
  require Logger
  require Matcha.Table.ETS

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
    table = Keyword.get(opts, :table, @table_name)

    Matcha.Table.ETS.select table, :reverse do
      {{time, _dup_number, key}, value} -> {time, key, value}
    end
  end

  def last(opts \\ []) do
    table = Keyword.get(opts, :table, @table_name)

    case :ets.last(table) do
      :"$end_of_table" ->
        :data_tracer_table_is_empty

      key ->
        [{{_time, _dup_number, _key}, value}] = :ets.lookup(table, key)
        value
    end
  end

  def store(value, opts \\ []) do
    key = Keyword.get(opts, :key)
    time = Keyword.get(opts, :time, :os.system_time(:millisecond))
    table = Keyword.get(opts, :table, @table_name)

    if key do
      Logger.warn("Storing #{inspect(key)}:#{inspect(time)} => #{inspect(value, pretty: true)}")
    else
      Logger.warn("Storing #{inspect(time)} => #{inspect(value, pretty: true)}")
    end

    store_value(table, time, key, value)
  end

  defp store_value(table, time, key, value, dup_number \\ 0) do
    if :ets.insert_new(table, {{time, dup_number, key}, value}) do
      :ok
    else
      store_value(table, time, key, value, dup_number + 1)
    end
  end

  def lookup(key, opts \\ []) do
    table = Keyword.get(opts, :table, @table_name)

    Matcha.Table.ETS.select table, :reverse do
      {{_time, _dup_number, the_key}, value} when key == the_key -> value
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
    :ets.new(table_name, [:ordered_set, :public, :named_table])
  end
end
