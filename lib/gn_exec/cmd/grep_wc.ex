 defmodule GnExec.Cmd.GrepWc do
  alias GnExec.Cmd

  @doc ~S"""
  Description

      iex> #GnExec.Cmd.GrepWc.cmd("QTL","README.md","result.out")
      :notimplemented

  """
  def start(query, input, output) do
       Cmd.exec("grep #{query} #{input} |wc -w > #{output}", {:output, output})
  end
end
