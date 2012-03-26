require "active_support"
require "active_support/cache"

class RedisStoreRails2 < ActiveSupport::Cache::Store
  def initialize(address=nil)
    address ||= "redis://localhost:6379"

    uri = URI.parse(address)
    options  = { :host => uri.host, :port => uri.port }
    password = uri.password || uri.user
    options.merge!(:password => password) if password
    @store = Redis.new(options)
  end

  def read(key, options = nil) # :nodoc:
    super
    @store.get(key)
  rescue Errno::ECONNREFUSED => e
    logger.error("RedisStoreRails2 error (#{e}): #{e.message}")
    nil
  end

  def write(key, value, options={})
    super
    response = @store.set(key, value)
    @store.expire(key, options[:expires_in]) if options[:expires_in]
    response == "OK"
  rescue Errno::ECONNREFUSED => e
    logger.error("RedisStoreRails2 error (#{e}): #{e.message}")
    false
  end

  def delete(key, options={})
    super
    response = @store.del(key)
    response >= 0
  end

  def increment(key, amount = 1)
    return nil unless @store.exists(key)
    @store.incrby key, amount
  end

  def decrement(key, amount = 1)
    return nil unless @store.exists(key)
    @data.decrby key, amount
  end

  def clear
    @store.flushdb
  end
end
