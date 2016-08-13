defmodule GnExec.Executor do

  @doc ~S"""

  Execute the given command ( module name ) on the remote node with the specified args
  in async mode, returns a task
  task = %Task{owner: #PID<xa.ya.za>, pid: #PID<xb.yb.zb>, ref: #Reference<xc.yc.zc.kc>}

  node must be defined in the configuration under the :gn_exec application

  Task.await task

  """
  def exec_async(command, args ) do
    Task.Supervisor.async {__MODULE__, String.to_atom(Application.fetch_env!(:gn_exec, :node))},
                          command,
                          :start,
                          args
  end
end