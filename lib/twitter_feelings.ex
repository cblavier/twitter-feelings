defmodule TwitterFeelings do

  def run do
    TF.TwitterSearch.search("lang:fr :)", 10)
  end


end
