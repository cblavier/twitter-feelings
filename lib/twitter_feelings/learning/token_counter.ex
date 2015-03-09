defmodule TwitterFeelings.Learning.TokenCounter do

  alias TwitterFeelings.Common.Redis

  use GenServer
  use TwitterFeelings.Common.GenServer.Stashable, stash_name: :token_counter_stash
  use TwitterFeelings.Common.GenServer.Startable
  use TwitterFeelings.Common.GenServer.Stoppable

  def clear(lang) do
    GenServer.call(__MODULE__, {:clear, lang})
  end

  def update_count(token, lang, mood) do
    GenServer.call(__MODULE__, {:update_count, token, lang, mood})
  end

  def initial_state do
    {
      Redis.load_script(delete_keys_script),
      Redis.load_script(update_counters_script)
    }
  end

  # server implementation

  def handle_call({:clear, lang}, _from, {delete_keys_sha, update_counters_sha}) do
    import Redis
    {:ok, _} = run(["EVALSHA", delete_keys_sha, 0, count_key(lang, "*")])
    {:ok, _} = run(["EVALSHA", delete_keys_sha, 0, count_key(lang, :positive, "*")])
    {:ok, _} = run(["EVALSHA", delete_keys_sha, 0, count_key(lang, :negative, "*")])
    {:ok, _} = run(["EVALSHA", delete_keys_sha, 0, positive_prob_key(lang, "*")])
    {:reply, :ok, {delete_keys_sha, update_counters_sha}}
  end

  def handle_call({:update_count, token, lang, mood}, _from, {delete_keys_sha, update_counters_sha}) do
    import Redis
    {:ok, _} = run([
      "EVALSHA", update_counters_sha, 3,
      count_key(lang, mood, token), count_key(lang, token), positive_prob_key(lang, token),
      Atom.to_string(mood)
    ])
    {:reply, :ok, {delete_keys_sha, update_counters_sha}}
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

  defp delete_keys_script do
    """
    for _,k in ipairs(redis.call('keys', ARGV[1])) do
      redis.call('del', k)
    end
    """
  end

end