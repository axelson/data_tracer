defmodule DataTracer.SupervisorUtils do
  @doc """
  Get the restart settings for a supervisor

  Example return value: `%{max_restarts: 3, max_seconds: 5}`
  """
  def restart_settings(supervisor_pid) do
    supervisor_state = :sys.get_state(supervisor_pid)
    max_restarts = supervisor_state |> elem(5)
    max_seconds = supervisor_state |> elem(6)

    %{max_restarts: max_restarts, max_seconds: max_seconds}
  end

  @doc """
  Find the chain of parent superivors for a given process

  Example return value: `{:ok, [#PID<0.275.0>, #PID<0.276.0>, #PID<0.283.0>]}`

  Returns `:error` if unable to find the supervisors for the process
  """
  def find_supervisors(application, pid) do
    top_level_supervisor = get_supervisor(application)

    case find_supervisors(top_level_supervisor, pid, []) do
      nil -> :error
      supervisors -> {:ok, Enum.reverse(supervisors)}
    end
  end

  defp find_supervisors(supervisor, pid, parents) do
    Supervisor.which_children(supervisor)
    |> Enum.find_value(fn
      # Found the pid
      {_, ^pid, _, _} ->
        [supervisor | parents]

      # Recurse down a supervisor
      {_id, child_pid, :supervisor, _modules} ->
        case find_supervisors(child_pid, pid, [supervisor | parents]) do
          nil -> nil
          results -> results
        end

      {_id, _child_pid, _type, _modules} ->
        nil
    end)
  end

  # Uses Erlang internals to find the top-level supervisor of an application
  defp get_supervisor(application) do
    {pid, _name} =
      :application_controller.get_master(application)
      |> :application_master.get_child()

    pid
  end

  @doc """
  Find the max number of crashes that the given PID can have before it brings
  down the entire application.

  NOTE: Currently assumes all the crashes happen at the same time (i.e.
  `max_seconds` is ignored)
  """
  def max_crashes(application, pid) do
    with {:ok, supervisors} <- find_supervisors(application, pid),
         restart_settings = Enum.map(supervisors, &restart_settings/1) do
      Enum.reduce(restart_settings, 1, fn restart_settings, acc ->
        num_crashes = restart_settings.max_restarts + 1
        acc * num_crashes
      end)
    end
  end
end
