defmodule TwitterFeelings do

  alias TwitterFeelings.CorpusBuilder.Builder,    as: Builder
  alias TwitterFeelings.CorpusBuilder.TweetStore, as: TweetStore

  @default_tweet_count 500_000
  @default_lang        "en"

  def main(argv) do
    TwitterFeelings.CorpusBuilder.Supervisor.start_link
    argv
      |> parse_args
      |> process
  end

  defp parse_args(argv) do
    {options, args, _} = OptionParser.parse(argv,
      switches: [ help: :boolean, lang: :string, mood: :string, tweet_count: :integer],
      aliases:  [ h: :help ]
    )
    options_map = Enum.into(options, %{lang: @default_lang, tweet_count: @default_tweet_count})
    case args do
      ["build-corpus"] ->
        case options_map do
          %{ lang: lang, mood: "positive", tweet_count: count } -> { lang, :positive, count }
          %{ lang: lang, mood: "negative", tweet_count: count } -> { lang, :negative, count }
          _ -> :help
        end
      _ -> :help
    end
  end

  defp process({lang, mood, tweet_count}) do
    lang_atom = if is_binary(lang), do: String.to_atom(lang), else: lang
    TweetStore.set_lang_and_mood(lang_atom, mood)
    Builder.build_corpus(lang_atom, mood, tweet_count)
  end

  defp process(:help) do
    IO.puts """
    usage: twitter_feelings build-corpus --lang [ language ] --mood [ positive | negative ] --tweet-count [ count ]
    """
  end

end
