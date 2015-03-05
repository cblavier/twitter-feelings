defmodule TwitterFeelings.TwitterFeelingsTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings, as: TF
  alias TwitterFeelings.CorpusBuilder.Supervisor, as: TSupervisor
  alias TwitterFeelings.CorpusBuilder.TweetStore
  alias TwitterFeelings.CorpusBuilder.Builder

  test "help" do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TwitterFeelings.main(["help"])
        assert called IO.puts(:_)
      end
    end
  end

  test "with all params in correct order" do
    mocking_app fn ->
      TF.main(args("build-corpus --lang fr --mood negative --tweet-count 2000"))
      assert called TweetStore.set_lang_and_mood(:fr, :negative)
      assert called Builder.build_corpus(:fr, :negative, 2000)
    end
  end

  test "with all params in whatever order" do
    mocking_app fn ->
      TF.main(args("build-corpus --tweet-count 2000 --mood negative --lang fr "))
      assert called TweetStore.set_lang_and_mood(:fr, :negative)
      assert called Builder.build_corpus(:fr, :negative, 2000)
    end
  end

  test "with missing lang, it default to en" do
    mocking_app fn ->
      TF.main(args("build-corpus --tweet-count 2000 --mood negative"))
      assert called TweetStore.set_lang_and_mood(:en, :negative)
      assert called Builder.build_corpus(:en, :negative, 2000)
    end
  end

  test "with missing tweet-count, it default to 500_000" do
    mocking_app fn ->
      TF.main(args("build-corpus --lang en --mood positive"))
      assert called TweetStore.set_lang_and_mood(:en, :positive)
      assert called Builder.build_corpus(:en, :positive, 500_000)
    end
  end

  test "with wrong mood, it prints help " do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TF.main(args("build-corpus --lang en --mood sad --tweet-count 2000"))
        assert called IO.puts(:_)
      end
    end
  end

  test "with wrong command, it prints help " do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TF.main(args("buildcorpus --lang en --mood positive --tweet-count 2000"))
        assert called IO.puts(:_)
      end
    end
  end

  def args(s), do: String.split(s)

  def mocking_app(fun) do
    with_mock TSupervisor, [start_link: fn -> end] do
      with_mock TweetStore, [set_lang_and_mood: fn(_,_) -> end] do
        with_mock Builder, [build_corpus: fn(_,_,_) -> end] do
          fun.()
        end
      end
    end
  end

end