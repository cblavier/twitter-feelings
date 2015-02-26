defmodule TF.TweetProcessor do

  def process(tweet_text) do
    String.downcase(tweet_text)
      |> String.split
      |> Stream.map(fn(text)    -> Regex.replace(~r/(\.|,|;|!|\?)/, text, "") end)      # removes punctuation
      |> Stream.reject(fn(text) -> Regex.match?(~r/^\s*$/, text) end)                   # remove empty strings
      |> Stream.reject(fn(text) -> Regex.match?(~r/^[a-zA_Z]{1,2}$/,text) end)          # remove very short words
      |> Stream.reject(fn(text) -> Regex.match?(~r/@\w+/, text) end)                    # remove usernames
      |> Stream.reject(fn(text) -> Regex.match?(~r/(?:http|https)\:\/\/\S+/, text) end) # remove urls
      |> Stream.map(fn(text)    -> Regex.replace(~r/(.)\1{2,}/, text, "\\1\\1") end)    # replace repeated characters
      |> Stream.map(fn(text)    -> Regex.replace(~r/:-?d/, text, ":D") end)             # replace mistakenly downcased smileys
      |> Enum.join " "
  end

  def valid?(text) do
    cond do
      String.contains?(text, "RT")                             -> false
      has_positive_smiley?(text) && has_negative_smiley?(text) -> false
      true                                                     -> true
    end
  end

  defp has_positive_smiley?(text) do
    String.contains?(text, [":)", ": )", ":-)", ":D", ":-D", "=)"])
  end

  defp has_negative_smiley?(text) do
    String.contains?(text, [":(", ": (", ":-("])
  end

end