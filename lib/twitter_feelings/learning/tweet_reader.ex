defmodule TwitterFeelings.Learning.TweetReader do

  alias TwitterFeelings.Common.Redis

  @page_size 100

  def stream(lang, mood) do
    Stream.unfold(0, &(read_tweets(&1,lang, mood)))
      |> Stream.flat_map(&(&1))
  end

  # private

  defp read_tweets("0", _, _), do: nil

  defp read_tweets(cursor, lang, mood) do
    {:ok, [next, tweets]} = Redis.run(["SSCAN", Redis.corpus_key(lang, mood), cursor, "COUNT", @page_size])
    {tweets, next}
  end

end