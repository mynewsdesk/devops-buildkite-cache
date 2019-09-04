RSpec.describe "pre-command" do
  it "parses the configuration" do
    ENV["BUILDKITE_PLUGIN_DEVOPS_BUILDKITE_CACHE_CONFIGURATION"] = %({
      "bundle-{{ 'Gemfile.lock' }}": "vendor/bundle",
      "node_modules-{{ 'yarn.lock' }}": "node_modules"
    })

    Dir.chdir "spec/dummy_environment" do
      system "../../hooks/pre-command"
    end
  end
end
