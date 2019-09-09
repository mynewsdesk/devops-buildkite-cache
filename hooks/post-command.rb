#!/usr/bin/env ruby

require "open3"
require_relative "../lib/buildkite-cache"

SSH_URL = ENV.fetch("BUILDKITE_CACHE_URL")
configuration = ENV["BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION"]
cache_keys_and_paths = BuildkiteCache.generate_configuration(configuration)

cache_keys_and_paths.each do |key, path|
  unless Dir.exist? path
    puts "Path '#{path}' doesn't exist. Skipping cache store."
    next
  end

  if system("ssh #{SSH_URL} 'find #{key}.tar'")
    puts "Cache already exists. Skipping cache store."
  else
    puts "Storing cache from '#{path}' in #{key}.tar"

    directory = File.dirname(key)

    system "ssh #{SSH_URL} 'mkdir -p ~/#{directory}'"
    system "tar c #{path} | ssh #{SSH_URL} 'cat > ~/#{key}.tar'"
  end

  if ENV.fetch("BUILDKITE_BRANCH") == "master"
    fallback_key = key.split("-")[0..-2].join("-") + "-master"
    system "ssh #{SSH_URL} 'ln -s ~/#{key}.tar ~/#{fallback_key}.tar'"
  end
end
