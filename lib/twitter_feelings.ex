defmodule TwitterFeelings do

  @default_query_count 450 # matches Twitter API rate limit for a 15mn window
  @default_lang        :en

  def main(argv) do
    CorpusBuilder.TwitterSearch.start_link
    CorpusBuilder.TweetStore.start_link
    argv
      |> parse_args
      |> process
  end

  defp parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help: :boolean, lang: :string, mood: :string, query_count: :integer],
      aliases:  [ h: :help ]
    )
    case parse do
    { [ help: true ] } -> :help
    { [ lang: lang, mood: "positive", query_count: count ], ["build-corpus"], _ } -> { lang, :positive, count }
    { [ lang: lang, mood: "negative", query_count: count ], ["build-corpus"], _ } -> { lang, :negative, count }
    { [ lang: lang, mood: "positive" ], ["build-corpus"], _ } -> { lang, :positive, @default_query_count }
    { [ lang: lang, mood: "negative" ], ["build-corpus"], _ } -> { lang, :negative, @default_query_count }
    _ -> :help
    end
  end

  defp process({lang, mood, query_count}) do
    lang_atom = String.to_atom(lang)
    CorpusBuilder.TweetStore.set_lang(lang)
    CorpusBuilder.TweetStore.set_mood(mood)
    CorpusBuilder.TwitterSearch.search_and_store(lang_atom, mood, query_count)
  end

  defp process(:help) do
    IO.puts """
    usage: twitter_feelings build-corpus --query-count [ count | #{@default_query_count} ] --mood [ positive | negative ] --lang [ language | #{@default_lang}]
    """
    System.halt(0)
  end

end
