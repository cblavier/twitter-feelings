defmodule TwitterFeelings do

  alias TwitterFeelings.CorpusBuilder.Builder
  alias TwitterFeelings.Learning.Learner

  @default_tweet_count 500_000
  @default_lang        "en"

  def main(argv) do
    TwitterFeelings.CorpusBuilder.Supervisor.start_link
    argv
      |> parse_args
      |> process
  end

  # private

  defp parse_args(argv) do
    {options, args, _} = OptionParser.parse(argv,
      switches: [ help: :boolean, lang: :string, mood: :string, count: :integer],
      aliases:  [ h: :help ]
    )
    options_map = Enum.into(options, %{lang: @default_lang, count: @default_tweet_count})
    case args do
      ["build-corpus"] ->
        case options_map do
          %{ lang: lang, mood: "positive", count: count } -> { :build_corpus, lang, :positive, count }
          %{ lang: lang, mood: "negative", count: count } -> { :build_corpus, lang, :negative, count }
          _ -> :help
        end
      ["learn"] ->
        case options_map do
          %{ lang: lang } -> { :learn, lang }
          _ -> :help
        end
      _ -> :help
    end
  end

  defp process({:build_corpus, lang, mood, tweet_count}) do
    Builder.build_corpus(lang_atom(lang), mood, tweet_count)
  end

  defp process({:learn, lang}) do
    Learner.learn(lang_atom(lang))
  end

  defp process(:help) do
    IO.puts """
    usage: twitter_feelings build-corpus --lang [ language ] --mood [ positive | negative ] --count [ count ]
    """
  end

  defp lang_atom(lang) do
    if is_binary(lang) do
      String.to_atom(lang)
    else
      lang
    end
  end

end
