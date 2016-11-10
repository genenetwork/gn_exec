defmodule GnExec.Executor do
  require Logger
  @doc ~S"""

  Execute the given command ( module name ) on the remote node with the specified args
  in async mode, returns a task
  task = %Task{owner: #PID<xa.ya.za>, pid: #PID<xb.yb.zb>, ref: #Reference<xc.yc.zc.kc>}

  node must be defined in the configuration under the :gn_exec application

  Task.await task

  """
  def exec_async(job, output_callback, transfer_callback, retval_callback ) do
    # {__MODULE__, String.to_atom(Application.fetch_env!(:gn_exec, :node))}
    Logger.debug "Executor.exec_async:start, #{job.token}"
    task = Task.Supervisor.async __MODULE__,
                          GnExec.Cmd,
                          :exec,
                          [
                            job,
                            output_callback,
                            transfer_callback,
                            retval_callback
                          ]
    Logger.debug "Executor.exec_async:end, token #{job.token}"
    # Set retval on remote server.
    # monitor_task(task)
  end

  def monitor_task(task) do
    case Task.yield(task) do
      nil -> monitor_task(task)
      {:ok, term} -> term
      {:exit, term} -> term
    end
  end
end
