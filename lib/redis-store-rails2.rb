require "active_support"
require "active_support/cache"

class RedisStoreRails2 < ActiveSupport::Cache::Store

  class Error < StandardError; end

  def initialize(address=nil)
    address ||= "redis://localhost:6379"

    uri = URI.parse(address)
    password = uri.password || uri.user
    @options  = { :host => uri.host, :port => uri.port }
    @options.merge!(:password => password) if password

    handle_errors do
      store # attempt to connect to Redis on boot
    end
  end

  def read(key, options = {})
    super
    handle_errors(options) do
      store.get(key)
    end
  end

  def write(key, value, options={})
    super
    handle_errors({ :default_value => false }.merge(options)) do
      response = if ttl = options[:expires_in]
        store.setex(key, ttl, value)
      else
        store.set(key, value)
      end
      response == "OK"
    end
  end

  def delete(key, options={})
    super
    handle_errors({ :default_value => false }.merge(options)) do
      response = store.del(key)
      response >= 0
    end
  end

  def increment(key, amount = 1, options={})
    handle_errors(options) do
      store.incrby(key, amount)
    end
  end

  def decrement(key, amount = 1, options={})
    handle_errors(options) do
      store.decrby(key, amount)
    end
  end

  def clear(options={})
    handle_errors(options) do
      store.flushdb
    end
  end

  protected

  def store
    @store ||= Redis.new(@options)
  end

  class RedisTimeoutError < Exception; end

  def handle_errors(options = {})
    Timeout.timeout(0.2, RedisTimeoutError) do
      return yield
    end
  rescue RedisTimeoutError, SystemCallError, SocketError, EOFError => e
    logger.error("RedisStoreRails2 error (#{e.class.name}): #{e.message}")
    raise RedisStoreRails2::Error.new(e.to_s) if options[:raise_errors]
    options[:default_value]
  end
end
