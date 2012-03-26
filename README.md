# Redis Store for Rails 2 apps

### Usage

Add to your Gemfile:

    gem "redis-store-rails2"

Then configure Rails:

    config.cache_store = :redis_store_rails2

By default it will attempt to connect to Redis running at localhost. To change:

    config.cache_store = :redis_store_rails2, "redis://1.2.3.4:5678"
