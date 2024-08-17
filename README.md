# DataTracer

Elixir debug tool to facilitate inspection of data flow by capturing terms for
inspection in IEx.

The primary intended usecase for DataTracer is to capture Elixir
terms—especially terms that are not printable or span many lines—and bringing
them into your IEx REPL. And yes, DataTracer is effectively global variables for
Elixir.

DataTracer doesn't have any dependencies.

**Warning** Not intended for use in production, may cause runaway memory use!

## Why create this?

I've found that when writing code I find it much easier to work with real data
and then quickly iterate in a REPL. But quite often the bit of data that I'm
interested in is "far" away from the command I run in IEx or could even only be
accessible from within the context of a Phoenix request. However, since
everything is happening within the same BEAM instance with a bit of plumbing
(enter DataTracer!) we can expose those values in a usable way.

DataTracer also helps with cases where code that you inspect is either too long
(or you forgot to include `limit: :infinity` when calling `IO.inspect`) or
contains a printout that can't be converted back to elixir terms, such as PIDs,
often only one part of a struct in a printout will be invalid, but that means
you can't simply copy the result to IEx, instead you have to first remove the
invalid bits which is time consuming and error prone.

## Installation

`DataTracer` can be installed by adding `data_tracer` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_tracer, "~> 0.1", only: [:dev]},
  ]
end
```

I recommend `only: [:dev]` because DataTracer is not intended for use in
production.

## Usage

For general usage of DataTracer I recommend starting your application with
`iex -S mix` (or `iex -S mix phx.server` for a Phoenix application)

``` elixir
# Somewhere in your code (such as a Phoenix Controller or LiveView)
DataTracer.store("earlier-value", key: "my-term")
DataTracer.store("some-value", key: "my-term")

# In IEx
iex> DataTracer.last(key: "my-term")
"some-value"
iex> DataTracer.lookup("my-term")
["some-value", "earlier-value"]

# Somewhere in your code (e.g. in a Phoenix Controller)
DataTracer.store(conn)
# Then access that controller by making a request to it, for example visit:
# http://localhost:4000/page?a_query_param=my_val

# In IEx
iex> conn = DataTracer.last()
conn = %Plug.Conn{
  adapter: {Plug.Cowboy.Conn, :...},
  assigns: %{flash: %{}},
  body_params: %{},
  cookies: %{},
  halted: false,
  ...
}
# Now you can inspect specific values of the `conn`
iex> conn.params
%{"a_query_param" => "my_val"}
```

Use cases:
- Capture a `pid`
- Capture values from a Phoenix request
- Collect many values over time so you can debug

## How it Works

DataTracer saves received terms to ETS and then looks them up from there. The
lookup should generally be fast because it's based on a key in an ordered set
table in ETS.

Insertion happens via a GenServer (`DataTracer.Server`) to ensure that race
conditions are handled.

Note: I've spent some effort to make DataTracer fast at lookups while not
compromising storage speed but I haven't done any benhcmarks and there's likely
lots of room for improvement.
