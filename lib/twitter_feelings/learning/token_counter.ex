defmodule TwitterFeelings.Learning.TokenCounter do

  use GenServer
  use TwitterFeelings.Common.GenServer.Stashable, stash_name: :token_counter_stash
  use TwitterFeelings.Common.GenServer.Startable
  use TwitterFeelings.Common.GenServer.Stoppable

  alias TwitterFeelings.Common.Redis

  def clear(lang) do
    GenServer.call(__MODULE__, {:clear, lang})
  end

  def update_count(token, lang, mood) do
    GenServer.call(__MODULE__, {:update_count, token, lang, mood})
  end

  def initial_state do
    Redis.load_script(update_counters_script)
  end

  # server implementation

  def handle_call({:clear, lang}, _from, update_counters_sha) do
    import Redis
    {:ok, _} = clear_keys(count_key(lang, "*"))
    {:ok, _} = clear_keys(count_key(lang, :positive, "*"))
    {:ok, _} = clear_keys(count_key(lang, :negative, "*"))
    {:ok, _} = clear_keys(positive_prob_key(lang, "*"))
    {:reply, :ok, update_counters_sha}
  end

  def handle_call({:update_count, token, lang, mood}, _from, update_counters_sha) do
    import Redis
    {:ok, _} = run([
      "EVALSHA", update_counters_sha, 3,
      count_key(lang, mood, token), count_key(lang, token), positive_prob_key(lang, token),
      Atom.to_string(mood)
    ])
    {:reply, :ok, update_counters_sha}
  end

  # private

  defp update_counters_script do
    """
    local mood_count  = redis.call("INCRBY", KEYS[1], 1)
    local total_count = redis.call("INCRBY", KEYS[2], 1)
    if ARGV[1] == "positive" then
      redis.call("SET", KEYS[3], mood_count / total_count)
    else
      redis.call("SET", KEYS[3],  1 - (mood_count / total_count))
    end
    """
  end


end