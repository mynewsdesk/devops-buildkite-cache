#!/usr/bin/env ruby

require "open3"
require_relative "../lib/buildkite-cache"

def restore_cache(key, path, fallbacks: nil)
  if Dir.exist? path
    puts "Path '#{path}' already exists. Skipping cache fetch."
    return
  end

  puts "Attempting to restore cache to #{path} from #{key}"

  ssh_url = ENV.fetch("BUILDKITE_CACHE_URL")
  command = "ssh #{ssh_url} 'cat #{key}.tar' | tar x"
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    puts "Successfully extracted cache into #{path}"
  else
    # If the command fails it will likely output
    # cat: dir/subdir/filename.tar: No such file or directory
    # tar: This does not look like a tar archive
    # tar: Exiting with failure status due to previous errors
    if stderr["No such file"]
      puts "No cache available. Skipping."

      if fallbacks
        # Fallbacks are based on the master branch, thus we replace the
        # last suffix with "master"
        fallback_key = key.split("-")[0..-2].join("-") + "-master"
        fallbacks[fallback_key] = path
      end
    else
      puts "ERROR restoring cache: #{stderr}"
    end
  end
end

configuration = ENV["BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION"]
cache_keys_and_paths = BuildkiteCache.generate_configuration(configuration)
fallbacks = {}

cache_keys_and_paths.each do |key, path|
  restore_cache(key, path, fallbacks: fallbacks)
end

fallbacks.each do |key, path|
  restore_cache(key, path)
end
