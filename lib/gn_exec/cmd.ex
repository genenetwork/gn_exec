defmodule GnExec.Cmd do

  @doc ~S"""
  Execute a command  and return its state and its stdout/stderr. Within loop would be possible to dipatch
  messages to some handler for monitoring the job activity (attach to some GenEnvent)

      iex> GnExec.Cmd.exec("ls")
      {0, ['LICENSE\nREADME.md\n_build\nconfig\ndoc\nlib\nmix.exs\ntest\n'], nil}

  """
  def exec(cmd, {:output, output} \\ {:output, nil}) do
    port=Port.open({:spawn, cmd},[:stream, :exit_status, :use_stdio, :stderr_to_stdout])
    loop(port, [],0, output)
  end

  @doc ~S"""
  Timeout could be used in the future to check is the process is still alive or not

  """
  def loop(port, cache, timeout, output) do
    receive do
      {^port, {:data, data}} -> 
        loop(port, [data | cache], timeout, output)
      {^port, {:exit_status, exit_status}} ->
        {exit_status, Enum.reverse(cache), output}
    end
  end
end