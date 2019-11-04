defmodule DataTracer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DataTracer.Server, []}
    ]

    opts = [strategy: :one_for_one, name: DataTracer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
