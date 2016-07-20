# GenExec usage

Start the GnServer with a name i.e. `master`

    iex --name executron -S min

Start the Executor with a name i.e. `executron`

    iex --name executron -S min


Dispatch the execution on the server side (remote node)

    iex(master@YOURMASTER)> task = Task.Supervisor.async {GnExec.Executor, :"executron@REMOTEHOSTNAME" }, GnExec.Cmd.GrepWc, :cmd, ["and","README.md","result.out"]
    %Task{owner: #PID<0.2616.0>, pid: #PID<39937.145.0>, ref: #Reference<0.0.2.11696>}
    
    iex(master@YOURMASTER)> Task.await(task)
    {0, [], "result.out"}