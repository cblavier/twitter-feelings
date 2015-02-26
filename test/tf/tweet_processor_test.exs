defmodule TF.TweetProcessorTest do
  use ExUnit.Case, async: true

  alias TF.TweetProcessor, as: TP

  # process

  test "process removes username from tweet" do
    assert TP.process("hello @username how are you") == "hello how are you"
  end

  test "process removes short words from tweets" do
    assert TP.process("hi how are u ?") == "how are"
  end

  test "process removes urls from tweets" do
    assert TP.process("have you seen http://google.fr") == "have you seen"
  end

  test "process removes characters repetition" do
    assert TP.process("that's really coooool") == "that's really cool"
  end

  test "process strips useless whitespaces" do
    assert TP.process(" hello  how are you    ") == "hello how are you"
  end

  test "process downcases everything" do
    assert TP.process("Hello how ARE you") == "hello how are you"
  end

  test "process keeps smileys" do
    assert TP.process("hello how are you ? :) :D") == "hello how are you :) :D"
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
