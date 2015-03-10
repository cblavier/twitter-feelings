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
        |> Stream.map(fn (tweet) ->
             Task.async(fn -> TokenCounter.update_count(tweet, lang, mood) end)
           end)
        |> Enum.map(&Task.await/1)
    end

    TokenCounter.update_tweet_prob_for_mood(lang)
  end

end