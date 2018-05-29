require 'rubygems'
require 'yaml'
require 'erb'
require 'redis'
require 'java'

java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'

require './tweet_fetcher'

class Twitty

  def initialize(env)
    puts "Twitty initialized...."
    @config = YAML.load(ERB.new(File.read("data/twitty.yml")).result).freeze
    @env = env
  end

  def refresh_main_data
    clear_cached_tweets
    load_main_data
    reload_main_cache
  end

  def clear_cached_tweets
    categories.each do |category|
      redis.del(tweet_info_key(category))
    end
  end

  def load_main_data
    puts "Loading main data...."
    executor = ThreadPoolExecutor.new(4, 4, 60, TimeUnit::SECONDS, LinkedBlockingQueue.new)
    tasks = []
    start_time = Time.now.to_i
    app_data.each do |category, celebs|
      puts "Creating thread..."
      task = FutureTask.new(TweetFetcher.new(category, celebs, redis))
      executor.execute(task)
      tasks << task
    end

    tasks.each do |t|
      t.get
    end

    puts "Loading complete </>"
    time_taken = Time.now.to_i - start_time
    puts "Time taken: #{time_taken}s"
    executor.shutdown()
  end

  def reload_main_cache
    cached_main_data(true)
  end

  def cached_main_data(force=false)
    if force || redis.get("main_data").to_s.blank?
      redis.set("main_data", main_data)
    end
    eval(redis.get('main_data'))
  end

  def main_data
    {}.tap do |data_hash|
      categories.each do |category|
        data_hash[category] = redis.zrevrange(tweet_info_key(category), 0, -1).first(100)
      end
      data_hash
    end
  end

  def categories
    app_data.keys
  end

  private

  def app_data
    @config["app_data"]
  end

  def tweet_info_key(category)
    "#{category}:tweets"
  end

  def redis
    @redis ||= Redis.new(YAML.load(ERB.new(File.read("config/redis.yml")).result)[@env])
  end
end
