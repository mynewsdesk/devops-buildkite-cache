#!/usr/bin/env ruby

require_relative "../lib/buildkite-cache"

configuration = ENV.fetch("BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION")
cache_keys_and_paths = BuildkiteCache.parse_configuration(configuration)

cache_keys_and_paths.each do |key, path|
  unless Dir.exist? path
    puts "Path '#{path}' doesn't exist. Skipping cache store."
    next
  end

  ssh_url = ENV.fetch("BUILDKITE_CACHE_URL")
  if system("ssh #{ssh_url} 'find #{key}.tar'")
    puts "Cache already exists. Skipping cache store."
  else
    puts "Storing cache from '#{path}' in #{key}.tar"

    directory = File.dirname(key)

    system "ssh #{ssh_url} 'mkdir -p ~/#{directory}'"
    system "tar c #{path} | ssh #{ssh_url} 'cat > ~/#{key}.tar'"
  end
end
