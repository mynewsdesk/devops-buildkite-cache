#!/usr/bin/env ruby

require "open3"
require_relative "../lib/buildkite-cache"

BUCKET_URL = ENV.fetch("BUILDKITE_CACHE_BUCKET", "s3://buildkite-cache-mnd/")

def restore_cache(key, path, fallbacks: nil)
  if Dir.exist? path
    puts "Path '#{path}' already exists. Skipping cache fetch."
    return
  end

  unless system("aws s3 ls #{BUCKET_URL}#{key}.tar")
    puts "#{BUCKET_URL}#{key}.tar doesn't exist. Skipping cache fetch."
  end

  puts "Attempting to restore cache to #{path} from #{key}"

  command = "aws s3 cp #{BUCKET_URL}#{key}.tar - | tar x"
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    puts "Successfully extracted cache into #{path}"
  else
    if stderr["Not Found"]
      # Expected output in case the cache file doesn't exist:
      # download failed: s3://buildkite-cache-mnd/perfectskies/mynewsdesk/node_modules-v10.12.0-5c6b842a83ee34a6a591b8477244561028630bdds.tar to - An error occurred (404) when calling the HeadObject operation: Not Found
      # tar: This does not look like a tar archive
      # tar: Exiting with failure status due to previous errors
      puts "No cache available. Skipping."
    elsif stderr["Unexpected EOF in archive"]
      # Expected output in case the cache file is corrupted (eg. due to canceling a job mid-cache):
      # ERROR restoring cache: tar: Unexpected EOF in archive
      # tar: Unexpected EOF in archive
      # tar: Error is not recoverable: exiting now
      puts "WARNING: Cache file appears corrupted. Deleting!"
      system "aws s3 rm #{BUCKET_URL}#{key}.tar"
    else
      puts "UNKNOWN ERROR restoring cache: #{stderr}"
    end

    if fallbacks
      # Fallbacks are based on the master branch, thus we replace the last suffix with "master".
      fallback_key = key.split("-")[0..-2].join("-") + "-master"
      fallbacks[fallback_key] = path
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
