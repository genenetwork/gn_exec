 defmodule GnExec.Cmd.Ls do
  alias GnExec.Cmd

  @doc ~S"""
  Description

      iex> #GnExec.Cmd.GrepWc.cmd("QTL","README.md","result.out")
      :notimplemented

  """
  def start(directory, parameters \\ '', output \\ :stdout) do
       Cmd.exec("ls #{parameters} #{directory}", {:output, output})
  end
end