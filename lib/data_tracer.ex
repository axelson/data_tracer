defmodule DataTracer do
  @moduledoc """
  Facilitates debugging by holding data traces of interesting data. Is a
  GenServer so it can own an ets table to store the data in.
  """

  @table_doc "`:table` - The ETS table to read from (optional, only needed if
  the table name was customized when the DataTracer was started)"

  @tracer_doc "`:tracer` - The DataTracer instance to store the value in. Defaults to #{__MODULE__}."

  @doc """
  Retrieve all entries that have been stored

  Options:
  * #{@table_doc}
  """
  defdelegate all, to: DataTracer.Server
  defdelegate all(opts), to: DataTracer.Server

  @doc """
  Retrieve the last entry that was stored

  See `last/1` for options
  """
  defdelegate last, to: DataTracer.Server
  defdelegate last(opts), to: DataTracer.Server

  @doc """
  Store the given value in the DataTracer uniquely

  The first instance of the found value is replaced with the new value

  See `store_uniq/2` for options
  """
  defdelegate store_uniq(value), to: DataTracer.Server

  @doc """
  Options:
  * `:key` - The key that the value is stored under. Defaults to `nil`
  * `:time` - The timestamp to associate with the value (primarily used for
    sorting). Defaults to the current time.
  * #{@tracer_doc}
  """
  defdelegate store_uniq(value, opts), to: DataTracer.Server

  @doc """
  Store the given value in the DataTracer

  see `store/2` for details
  """
  defdelegate store(value), to: DataTracer.Server

  @doc """
  Store the given value in the DataTracer

  Options:
  * `:key` - The key that the value is stored under. Defaults to `nil`
  * `:time` - The timestamp to associate with the value (primarily used for
    sorting). Defaults to the current time.
  * #{@tracer_doc}
  """
  defdelegate store(value, opts), to: DataTracer.Server

  @doc """
  Retrieve all values that have been stored under the key in the DataTracer

  Returns the values in desc order by timestamp. This means that the first value
  returned is the last value that was stored for the given key.

  Use `nil` as the key to retrieve values that were stored without a specific key.

  Options:
  * #{@table_doc}
  """
  defdelegate lookup(key), to: DataTracer.Server
  defdelegate lookup(key, opts), to: DataTracer.Server

  @doc """
  Clear the DataTracer

  see `clear/1` for details
  """
  defdelegate clear, to: DataTracer.Server

  @doc """
  Clear the DataTracer

  Options:
  * #{@tracer_doc}
  """
  defdelegate clear(opts), to: DataTracer.Server
end
