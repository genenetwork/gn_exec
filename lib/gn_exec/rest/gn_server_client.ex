defmodule GnExec.Rest.Client do
  use HTTPoison.Base

  @expected_fields ~w(
    token command args
  )

  def process_url(url) do
    server_url = Application.get_env(:gn_exec, :gn_server_url)
    server_url <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!(as: %GnExec.Rest.Job{})
    # |> Map.take(@expected_fields)

    #|> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def get_job(program, parameter) do
    get!(program <> "/" <> parameter <> ".json").body
  end
end
