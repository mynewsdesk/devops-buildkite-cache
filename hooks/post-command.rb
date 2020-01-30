#!/usr/bin/env ruby

exit if ENV["BUILDKITE_CACHE_DISABLE"] == "true"

require "open3"
require_relative "../lib/buildkite-cache"

last_exit_status = ENV.fetch("BUILDKITE_COMMAND_EXIT_STATUS")
if last_exit_status != "0"
  puts "Skipping cache plugin since the build appears to have failed (BUILDKITE_COMMAND_EXIT_STATUS was #{last_exit_status})"
  exit
end

BUCKET_URL = ENV.fetch("BUILDKITE_CACHE_BUCKET", "s3://buildkite-cache-mnd/")
configuration = ENV["BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION"]
cache_keys_and_paths = BuildkiteCache.generate_configuration(configuration)

cache_keys_and_paths.each do |key, path|
  unless Dir.exist? path
    puts "Path '#{path}' doesn't exist. Skipping cache store."
    next
  end

  tar_path = "#{BUCKET_URL}#{key}.tar"

  if system("aws s3 ls #{tar_path}")
    puts "Cache already exists. Skipping cache store."
  else
    puts "Storing cache from '#{path}' in #{tar_path}"

    system "tar c #{path} | aws s3 cp - #{tar_path}"
  end

  if ENV.fetch("BUILDKITE_BRANCH") == "master"
    fallback_key = key.split("-")[0..-2].join("-") + "-master"
    fallback_path = "#{BUCKET_URL}#{fallback_key}.tar"
    puts "Copying #{tar_path} to #{fallback_path}"
    system "aws s3 cp #{tar_path} #{fallback_path}"
  end
end
