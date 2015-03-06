defmodule TwitterFeelings.CorpusBuilder.TweetnormalizeorTest do

  use ExUnit.Case, async: true

  alias TwitterFeelings.CorpusBuilder.TweetProcessor, as: TP

  # normalize

  test "normalize removes username from tweet" do
    assert TP.normalize("hello @username how are you") == "hello how are you"
  end

  test "normalize removes short words from tweets" do
    assert TP.normalize("hi how are u ?") == "how are"
  end

  test "normalize removes urls from tweets" do
    assert TP.normalize("have you seen http://google.fr") == "have you seen"
  end

  test "normalize removes characters repetition" do
    assert TP.normalize("that's really coooool") == "that's really cool"
  end

  test "normalize strips useless whitespaces" do
    assert TP.normalize(" hello  how are you    ") == "hello how are you"
  end

  test "normalize downcases everything" do
    assert TP.normalize("Hello how ARE you") == "hello how are you"
  end

  test "remove accents" do
    assert TP.normalize("ce tweet est très accentué. Très!") == "tweet est tres accentue tres"
  end

  test "it keeps smileys and appends them at the end" do
    assert TP.normalize("that's really cool :)") == "that's really cool :)"
    assert TP.normalize(":) that's really cool :)") == "that's really cool :) :)"
    assert TP.normalize(":((( that's not cool") == "that's not cool :((("
    assert TP.normalize("that's :p :) really :DD cool") == "that's really cool :) :DD"
  end

  # valid?

  test "basic tweet is valid" do
    assert TP.valid?("lorem ipsum sed doloris")
  end

  test "tweet containing RT is not valid" do
    refute TP.valid?("plop RT some text")
  end

  test "tweet containing positive smiley is valid" do
    assert TP.valid?("plop :) some text")
    assert TP.valid?("plop :-) some text")
  end

  test "tweet containing negative smiley is valid" do
    assert TP.valid?("plop :( some text")
    assert TP.valid?("plop :-( some text")
  end

  test "tweet containing both positive and negative smileys is invalid" do
    refute TP.valid?("plop :( some text :D")
    refute TP.valid?("plop :-( some :) text")
  end

end
