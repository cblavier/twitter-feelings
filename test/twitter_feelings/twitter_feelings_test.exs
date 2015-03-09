defmodule TwitterFeelings.TwitterFeelingsTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings.CorpusBuilder.Supervisor, as: TSupervisor
  alias TwitterFeelings.CorpusBuilder.Builder
  alias TwitterFeelings.Learning.Learner

  test "help" do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TwitterFeelings.main(["help"])
        assert called IO.puts(:_)
      end
    end
  end

  test "build-corpus with all params in correct order" do
    mocking_app fn ->
      TwitterFeelings.main(args("build-corpus --lang fr --mood negative --count 2000"))
      assert called Builder.build_corpus(:fr, :negative, 2000)
    end
  end

  test "build-corpus with all params in whatever order" do
    mocking_app fn ->
      TwitterFeelings.main(args("build-corpus --count 2000 --mood negative --lang fr "))
      assert called Builder.build_corpus(:fr, :negative, 2000)
    end
  end

  test "build-corpus with missing lang, it default to en" do
    mocking_app fn ->
      TwitterFeelings.main(args("build-corpus --count 2000 --mood negative"))
      assert called Builder.build_corpus(:en, :negative, 2000)
    end
  end

  test "build-corpus with missing tweet-count, it default to 500_000" do
    mocking_app fn ->
      TwitterFeelings.main(args("build-corpus --lang en --mood positive"))
      assert called Builder.build_corpus(:en, :positive, 500_000)
    end
  end

  test "build-corpus with wrong mood, it prints help " do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TwitterFeelings.main(args("build-corpus --lang en --mood sad --count 2000"))
        assert called IO.puts(:_)
      end
    end
  end

  test "learn with lang param" do
    mocking_app fn ->
      TwitterFeelings.main(args("learn --lang fr"))
      assert called Learner.learn(:fr)
    end
  end

  test "learn with no param" do
    mocking_app fn ->
      TwitterFeelings.main(args("learn"))
      assert called Learner.learn(:en)
    end
  end

  test "with wrong command, it prints help " do
    mocking_app fn ->
      with_mock IO, [puts: fn(_) -> end] do
        TwitterFeelings.main(args("buildcorpus --lang en --mood positive --count 2000"))
        assert called IO.puts(:_)
      end
    end
  end

  def args(s), do: String.split(s)

  def mocking_app(fun) do
    with_mock TSupervisor, [start_link: fn -> end] do
      with_mock Builder, [build_corpus: fn(_,_,_) -> end] do
        with_mock Learner, [learn: fn(_) -> end] do
          fun.()
        end
      end
    end
  end

end