defmodule DataTracer.Server do
  @moduledoc """
  Reads and writes the traced data to ETS

  Data format `{key, timestamp, value}`
  """

  use GenServer
  require Logger

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
    table_name = get_table(opts)
    table = new(table_name)
    {:ok, %State{table_name: table_name, table: table}}
  end

  def all(opts \\ []) do
    table = get_table(opts)
    # {{time, _dup_number, key}, value} -> {time, key, value}
    match_spec = [{{{:"$1", :_, :"$2"}, :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]
    :ets.select_reverse(table, match_spec)
  end

  def last(opts \\ []) do
    table = get_table(opts)

    case :ets.last(table) do
      :"$end_of_table" ->
        :data_tracer_table_is_empty

      key ->
        [{{_time, _dup_number, _key}, value}] = :ets.lookup(table, key)
        value
    end
  end

  def store(value, opts \\ []) do
    key = get_key(opts)
    time = get_time(opts)
    table = get_table(opts)

    if key do
      Logger.warning(
        "Storing #{inspect(key)}:#{inspect(time)} => #{inspect(value, pretty: true)}"
      )
    else
      Logger.warning("Storing #{inspect(time)} => #{inspect(value, pretty: true)}")
    end

    store_value(table, time, key, value)
  end

  def store_uniq(value, opts \\ []) do
    key = get_key(opts)
    time = get_time(opts)
    table = get_table(opts)

    :ets.insert(table, {{time, _dup_number = 0, key}, value})
    value
  end

  defp store_value(table, time, key, value, dup_number \\ 0) do
    unless is_integer(time),
      do: raise("Timestamp must be an integer (that represents a unix timestamp)")

    if :ets.insert_new(table, {{time, dup_number, key}, value}) do
      value
    else
      store_value(table, time, key, value, dup_number + 1)
    end
  end

  def lookup(key, opts \\ []) do
    table = get_table(opts)

    # {{_time, _dup_number, the_key}, value} when key == the_key -> value
    match_spec = [
      {{{:_, :_, :"$3"}, :"$4"}, [{:==, :"$3", key}], [:"$4"]}
    ]

    :ets.select_reverse(table, match_spec)
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

  defp get_time(opts) when is_list(opts),
    do: Keyword.get(opts, :time, :os.system_time(:millisecond))

  defp get_table(opts) when is_list(opts), do: Keyword.get(opts, :table, @table_name)
  defp get_key(opts) when is_list(opts), do: Keyword.get(opts, :key, nil)
end
