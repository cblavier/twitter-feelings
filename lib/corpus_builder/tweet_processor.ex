defmodule CorpusBuilder.TweetProcessor do

  def normalize(tweet_text) do
    String.downcase(tweet_text)
      |> String.split
      |> Stream.map(fn(text)    -> remove_accents(text) end)                            # removes accents
      |> Stream.reject(fn(text) -> Regex.match?(~r/@\w+/, text) end)                    # remove usernames
      |> Stream.reject(fn(text) -> Regex.match?(~r/(?:http|https)\:\/\/\S+/, text) end) # remove urls
      |> Stream.map(fn(text)    -> Regex.replace(~r/[^a-z0-9'# ]/, text, " ") end)      # removes punctuation
      |> Stream.map(fn(text)    -> Regex.replace(~r/(.)\1{2,}/, text, "\\1\\1") end)    # replace repeated characters
      |> Stream.reject(fn(text) -> Regex.match?(~r/^\s*$/, text) end)                   # remove empty strings
      |> Stream.map(fn(text)    -> Regex.replace(~r/^[\s]+|[\s]+$/, text, "") end)      # remove leading and trailing spaces
      |> Stream.reject(fn(text) -> Regex.match?(~r/^[a-zA_Z]{1,2}$/,text) end)          # remove very short words
      |> Enum.join " "
  end

  def valid?(text) do
    cond do
      String.contains?(text, "RT")                             -> false
      has_positive_smiley?(text) && has_negative_smiley?(text) -> false
      true                                                     -> true
    end
  end

  def remove_accents(text) do
    text
      |> String.replace(~r/(ä|â|à|á|ã|å|ā)/, "a")
      |> String.replace(~r/(ë|ê|è|é|ę|ė|ē)/, "e")
      |> String.replace(~r/(ï|î|ì|í|į|ī)/, "i")
      |> String.replace(~r/(ö|ô|ò|ò|ó|õ|ø|ō)/, "o")
      |> String.replace(~r/(ü|û|ù|ú|ū)/, "u")
      |> String.replace(~r/(ç|ć|č)/, "c")
  end

  defp has_positive_smiley?(text) do
    String.contains?(text, [":)", ": )", ":-)", ":D", ":-D", "=)"])
  end

  defp has_negative_smiley?(text) do
    String.contains?(text, [":(", ": (", ":-("])
  end

end