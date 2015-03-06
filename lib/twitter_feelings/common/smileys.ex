defmodule TwitterFeelings.Common.Smileys do

  def positive do
    [":)", ":-)", ":D", ":-D", "=)"]
  end

  def negative do
    [":(", ":-(", "=(", ":'("]
  end

  def all do
    positive ++ negative
  end

end