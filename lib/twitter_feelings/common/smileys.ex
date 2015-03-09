defmodule TwitterFeelings.Common.Smileys do

  def positive do
    [":)", ":-)", ":D", ":-D", "=)", ":p"]
  end

  def negative do
    [":(", ":-(", "=(", ":'("]
  end

  def all do
    positive ++ negative
  end

end