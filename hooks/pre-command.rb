#!/usr/bin/env ruby

require_relative "../lib/buildkite-cache"

configuration = ENV.fetch("BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION")
cache_keys_and_paths = BuildkiteCache.parse_configuration(configuration)

cache_keys_and_paths.each do |key, path|
  if Dir.exist? path
    puts "Path '#{path}' already exists. Skipping cache fetch."
  else
    puts "Attempting to restore cache to #{path} from #{key}"
    ssh_url = ENV.fetch("BUILDKITE_CACHE_URL")
    command = "ssh #{ssh_url} 'cat #{key}.tar' | tar x"
    stdout, stderr, status = Open3.capture3(command)

    unless status.success?
      # If the command fails it will likely output
      # cat: dir/subdir/filename.tar: No such file or directory
      # tar: This does not look like a tar archive
      # tar: Exiting with failure status due to previous errors
      if stderr["No such file"]
        puts "No cache available. Skipping."
      else
        puts "ERROR restoring cache: #{stderr}"
      end
      next
    end

    puts "Successfully extracted cache into #{path}"
  end
end
