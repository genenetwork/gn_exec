defmodule GnExec.Rest.Client do
  use HTTPoison.Base

  # @expected_fields ~w(
  #   token command args
  # )

  def process_url(url) do
    server_url = Application.get_env(:gn_exec, :gn_server_url)
    server_url <> url
  end

  def process_response_body(body) do
    body
    #|> Poison.decode!(as: %GnExec.Rest.Job{})
    # |> Map.take(@expected_fields)

    #|> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def get_a_job(program, parameter) do
    get!(program <> "/dataset.json").body
    |> Poison.decode!(as: %GnExec.Rest.Job{})
  end

  def get_status(token) do
    IO.puts "program/" <> token <> "/status.json"
    get!("program/" <> token <> "/status.json").body
    |> Poison.decode!(as: %GnExec.Rest.JobStatus{} )
  end


  def set_status(token, progress) do
    url = Application.get_env(:gn_exec, :gn_server_url)
    response = put!("program/" <> token <> "/status.json",{:form, [{:progress, progress}]})

  end
end
