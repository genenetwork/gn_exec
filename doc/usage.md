# GenExec usage


## GnServer

### Configuration

Configure the name of the remote node that executes the GnExec app inside the `config.exs`

    config :gn_exec,
      node: "executron"

Add the dependency in `mix.exs`

    {:gn_exec, "~> 0.1.0", path: "../gn_exec/"}

`path` in case you have the source code ( right now the only way to get `gn_exec`)

### Running the app

Start the GnServer with a name i.e. `master`

    iex --name master -S min

### Call a remote excution

List the content of the direcotry `"."` inside the gn_server source repo

    task = GnExec.Executor.exec_async GnExec.Cmd.Ls, ["."]

wait for the response from the remote host

    Task.await(taks)
    {0,
 ['LICENSE\nREADME.md\n_build\nconfig\ndoc\nlib\nmix.exs\ntest\n'],
 :stdout}


## GnExec

### Running the app

Start the Executor with a name i.e. `executron`

    iex --name executron -S min