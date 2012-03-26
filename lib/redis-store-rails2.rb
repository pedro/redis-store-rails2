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
  end

  def write(key, value, options={})
    super
    response = @store.set(key, value)
    @store.expire(key, options[:expires_in]) if options[:expires_in]
    response == "OK"
  end
end
