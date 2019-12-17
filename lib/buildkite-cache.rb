require "json"
require "digest"

module BuildkiteCache
  ORGANIZATION = ENV.fetch("BUILDKITE_ORGANIZATION_SLUG").freeze
  PIPELINE = ENV.fetch("BUILDKITE_PIPELINE_SLUG").freeze

  def self.generate_configuration(json_string = nil)
    keys_and_paths = json_string ? parse_configuration(json_string) : {}

    if File.exist?("Gemfile.lock") && ENV["BUILDKITE_CACHE_DISABLE_RUBY"] != "true"
      ruby_version = language_version(".ruby-version")
      checksum = checksum("Gemfile.lock")
      key = key("bundle-#{ruby_version}-#{checksum}")
      keys_and_paths[key] = "vendor/bundle"
    end

    if File.exist?("yarn.lock") && ENV["BUILDKITE_CACHE_DISABLE_NODE"] != "true"
      node_version = language_version(".node-version", ".nvmrc")
      checksum = checksum("yarn.lock")
      key = key("node_modules-#{node_version}-#{checksum}")
      keys_and_paths[key] = "node_modules"
    end

    keys_and_paths
  end

  def self.parse_configuration(json_string)
    raw_keys_and_paths = JSON.parse(json_string)

    keys_and_paths = {}

    raw_keys_and_paths.each do |raw_key, path|
      suffix = raw_key.gsub %r({{(.*)}}) do
        filename = $1.strip
        checksum(filename)
      end
      key = key(suffix)
      keys_and_paths[key] = path
    end

    keys_and_paths
  end

  def self.checksum(filename)
    content = File.read(filename)
    Digest::SHA1.hexdigest(content)
  end

  def self.key(suffix)
    "#{ORGANIZATION}/#{PIPELINE}/#{suffix}"
  end

  def self.language_version(*filenames)
    filenames.each do |filename|
      return File.read(filename).gsub(/\s/, "") if File.exist?(filename)
    end
  end
end
