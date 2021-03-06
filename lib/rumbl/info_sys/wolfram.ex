defmodule Rumbl.InfoSys.Wolfram do
	import SweetXml
	import Ecto.Query, only: [from: 2]
	alias Rumbl.InfoSys.Result

	def start_link(query, query_ref, owner, limit) do
		Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
	end

	def fetch(query_str, query_ref, owner, _limit) do
		query_str
		|> fetch_xml()
		|> xpath(~x"/queryresult/pod[contains(@title, 'Definitions')]/subpod/plaintext/text()")
		#|> xpath(~x"/queryresult/pod/subpod/plaintext/text()")
		|> send_results(query_ref, owner)
	end

	defp send_results(nil, query_ref, owner) do
		send(owner, {:resluts, query_ref, []})
	end

	defp send_results(answer, query_ref, owner) do
		results = [%Result{backend: user(), score: 95, text: to_string(answer)}]
		send(owner, {:resluts, query_ref, results})
	end

	defp fetch_xml(query_str) do
		query = String.to_char_list("http://api.wolframalpha.com/v2/query" <>
        "?appid=#{app_id()}" <>
      "&input=#{URI.encode(query_str)}&format=plaintext")
		IO.puts query
	  {:ok, {_, _, body}} = :httpc.request(query)
    body
  end

	defp app_id, do: Application.get_env(:rumbl, :wolfram)[:app_id]

	defp user() do
		Rumbl.Repo.one!(from u in Rumbl.User, where: u.username == "wolfram")
	end

end
