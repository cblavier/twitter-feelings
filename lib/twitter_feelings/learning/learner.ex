defmodule TwitterFeelings.Learning.Learner do

  require Logger

  alias TwitterFeelings.Learning.TweetReader
  alias TwitterFeelings.Learning.TokenCounter

  def learn(lang) do
    Logger.debug "Clearing any existing counter for #{lang} lang."
    TokenCounter.clear(lang)

    for mood <- [:negative, :positive] do
      Logger.debug "Learning from #{mood} #{lang} tweets"
      TweetReader.stream(lang, mood)
        |> Stream.flat_map(&String.split/1)
        |> Stream.map(fn (token) ->
             Task.async(fn -> TokenCounter.update_count(token, lang, mood) end)
           end)
        |> Enum.map(&Task.await/1)
    end
  end

end