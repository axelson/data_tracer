defmodule DataTracer do
  @moduledoc """
  Facilitates debugging by holding data traces of interesting data. Is a
  GenServer so it can own an ets table to store the data in.
  """

  defdelegate all, to: DataTracer.Server
  defdelegate all(opts), to: DataTracer.Server

  defdelegate last, to: DataTracer.Server
  defdelegate last(opts), to: DataTracer.Server

  defdelegate store(value), to: DataTracer.Server
  defdelegate store(value, opts), to: DataTracer.Server

  defdelegate lookup(key), to: DataTracer.Server
  defdelegate lookup(key, opts), to: DataTracer.Server

  defdelegate clear, to: DataTracer.Server
  defdelegate clear(opts), to: DataTracer.Server
end
