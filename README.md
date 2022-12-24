# DataTracer

Elixir library to facilitate debugging data flow, helps capture terms for later inspection

## Installation

DataTracer is available via GitHub. Install it by adding `data_tracer` to your
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_tracer, github: "axelson/data_tracer"},
  ]
end
```

TODO:
- [ ] Don't unnecessarily send logs through the server (since we're using ETS we can write directly)
- [ ] Allow storing only new values (or only values that differ from the latest value)
