defmodule GnExec.Web.Management do
  use Maru.Router
  alias GnExec.Registry
  # alias GnExec.Job
  require Logger

  get "/list" do
    data = Registry.list|> Enum.map(fn({token, {job, status}})-> %{token: token, status: status} end )
    json(conn, data)
  end
end
