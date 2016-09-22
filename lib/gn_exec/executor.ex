defmodule GnExec.Executor do

  @doc ~S"""

  Execute the given command ( module name ) on the remote node with the specified args
  in async mode, returns a task
  task = %Task{owner: #PID<xa.ya.za>, pid: #PID<xb.yb.zb>, ref: #Reference<xc.yc.zc.kc>}

  node must be defined in the configuration under the :gn_exec application

  Task.await task

  """
  def exec_async(command, args, job ) do
    # {__MODULE__, String.to_atom(Application.fetch_env!(:gn_exec, :node))}
    task = Task.Supervisor.async __MODULE__,
                          command,
                          :start,
                          args
    #IO.puts inspect task
    # TODO put retval from here.
    {retval, _, _ } = monitor_task(task)
    GnExec.Rest.Job.set_retval(job, retval)

  end

  defp monitor_task(task) do
    case Task.yield(task) do
      nil -> monitor_task(task)
      {:ok, term} -> term
      {:exit, term} -> term
    end
  end
end
