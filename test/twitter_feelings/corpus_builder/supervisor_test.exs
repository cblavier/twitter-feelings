defmodule TwitterFeelings.CorpusBuilder.SupervisorTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings.CorpusBuilder.Supervisor, as: TSupervisor
  alias TwitterFeelings.CorpusBuilder.TweetStore
  alias TwitterFeelings.CorpusBuilder.Builder

  setup do
    TSupervisor.start_link
    monitor = Process.monitor(TSupervisor)
    {:ok, [monitor: monitor]}
  end

  test "when TweetStore fails, it is restored with state", %{monitor: monitor} do
    with_mock HTTPoison, [post!: fn(_,_,_) -> token_response end] do
      TweetStore.set_lang_and_mood(:fr, :positive)
      TweetStore.stop

      assert_receive {:DOWN, ^monitor, _, _, _}
      assert_server_state TweetStore, {:fr, :positive}
    end
  end

  test "when Builder fails, it is restored with state", %{monitor: monitor} do
    Builder.stop

    assert_receive {:DOWN, ^monitor, _, _, _}
    assert_server_state Builder, :no_max_id
  end

  def assert_server_state(server, state) do
    :timer.sleep(50)
    tweetstore_state = apply(server, :state, [])
    assert ^tweetstore_state = state
  end

  def token_response do
    %HTTPoison.Response {
      status_code: 200,
      body: ~s/{ "access_token": "a_token" }/
    }
  end

end