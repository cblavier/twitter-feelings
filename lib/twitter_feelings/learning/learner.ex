defmodule TwitterFeelings.Learning.Learner do

  require Logger

  alias TwitterFeelings.Learning.TweetReader
  alias TwitterFeelings.Learning.TokenCounter

  def learn(lang) do
    Logger.debug "Clearing any existing counter for #{lang} lang."
    TokenCounter.clear(lang)

    count = min(TweetReader.count(lang, :positive), TweetReader.count(lang, :negative))

    for mood <- [:negative, :positive] do
      Logger.debug "Learning from #{count} #{mood} #{lang} tweets"
      TweetReader.stream(lang, mood)
        |> Stream.take(count)
        |> Stream.map(fn (tweet) ->
             Task.async(fn -> TokenCounter.update_count(tweet, lang, mood) end)
           end)
        |> Enum.map(&Task.await/1)
    end
  end

end