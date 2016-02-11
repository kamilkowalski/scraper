require "./lib/logger"
require "./lib/cluster"
require "./lib/worker"

require "yaml"
require "pg"
require "nokogiri"
require "open-uri"

config = __dir__ + "/config.yml"

cluster = Scraper::Cluster.new(config: config)
cluster.start
