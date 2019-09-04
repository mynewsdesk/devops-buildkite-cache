require "json"
require "open3"

module BuildkiteCache
  ORGANIZATION = ENV.fetch("BUILDKITE_ORGANIZATION_SLUG").freeze
  PIPELINE = ENV.fetch("BUILDKITE_PIPELINE_SLUG").freeze

  def self.parse_configuration(json_string)
    raw_keys_and_paths = JSON.parse(json_string)

    keys_and_paths = {}

    raw_keys_and_paths.each do |raw_key, path|
      key = raw_key.gsub %r({{(.*)}}) do
        filename = $1.strip
        checksum(filename)
      end
      key = "#{ORGANIZATION}/#{PIPELINE}/#{key}"
      keys_and_paths[key] = path
    end

    keys_and_paths
  end

  def self.checksum(filename)
    stdout, stderr, status = Open3.capture3("sha1sum #{filename}")

    unless status.success?
      # likely stderr: "sha1sum: checksum: No such file or directory"
      abort "ERROR: Failed to get checksum of '#{filename}'.\n#{stderr}"
    end

    # stdout: "<checksum> <filename>\n"
    stdout.split(" ").first
  end
end
