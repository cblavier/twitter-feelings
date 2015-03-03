defmodule TwitterFeelings.CorpusBuilder.TwitterSearch do

  use GenServer

  @page_size 100

  alias TwitterFeelings.CorpusBuilder.TwitterRateLimiter, as: RateLimiter

  def start_link do
    GenServer.start_link(__MODULE__, bearer_token, name: __MODULE__)
  end

  def search(lang, mood, max_id) do
    { statuses, max_id } = GenServer.call(__MODULE__, {:search, lang, mood, max_id}, :infinity)
    { :ok, statuses, max_id}
  end

  # server implementation

  def handle_call({:search, lang, mood, max_id}, _from, token) do
    reply = RateLimiter.handle_rate_limit fn ->
      json = twitter_search(search_params(lang, mood, max_id), token)
      { get_in(json, ["statuses"]), new_max_id(json) }
    end
    { :reply, reply, token }
  end

  # private

  # twitter_search is bypassing most of ExTwitter implementation in order to use "Application only authentication".
  # This kind of authentication (using a bearer token) allow us to get higher rate limits.
  defp twitter_search(params, token) do
    {_, response} = HTTPoison.get(
      "https://api.twitter.com/1.1/search/tweets.json",
      ["Authorization": "Bearer #{token}"],
      params: params
    )
    case response.status_code do
      200 -> response.body |> JSX.decode!
      429 -> raise_rate_limit_error(response)
      _   -> raise_twitter_error(response)
    end
  end

  defp bearer_token do
    response = HTTPoison.post!(
      "https://api.twitter.com/oauth2/token",
      "grant_type=client_credentials",
      ["Authorization": "Basic #{bearer_token_credential}", "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"]
    )
    response.body |> JSX.decode! |> get_in(["access_token"])
  end

  defp bearer_token_credential do
    oauth = Application.get_env(:ex_twitter, :oauth, [])
    credential = URI.encode_www_form(oauth[:consumer_key]) <> ":" <> URI.encode_www_form(oauth[:consumer_secret])
    Base.encode64(credential)
  end

  defp raise_rate_limit_error(response) do
    {reset_at, _} = Integer.parse(response.headers["x-rate-limit-reset"])
    reset_in = Enum.max([reset_at - Timex.Date.now(:secs), 0])
    json = response.body |> JSX.decode!
    raise ExTwitter.RateLimitExceededError,
          code: Enum.at(json["errors"], 0)["code"], message: Enum.at(json["errors"], 0)["message"],
          reset_at: reset_at, reset_in: reset_in
  end

  defp raise_twitter_error(response) do
    json = response.body |> JSX.decode!
    raise ExTwitter.Error, code: Enum.at(json["errors"], 0)["code"], message: Enum.at(json["errors"], 0)["message"]
  end

  defp search_params(lang, mood, :no_max_id), do: %{q: query(mood), lang: "#{lang}", include_entities: false, count: @page_size}
  defp search_params(lang, mood, max_id),     do: %{q: query(mood), lang: "#{lang}", include_entities: false, count: @page_size, max_id: max_id}

  defp query(:positive), do: ":)"
  defp query(:negative), do: ":("

  defp new_max_id(json) do
    next_results = get_in(json, ["search_metadata", "next_results"])
    Regex.named_captures(~r/max_id=(?<max_id>\w+)&/, next_results)["max_id"]
      |> String.to_integer
  end

end