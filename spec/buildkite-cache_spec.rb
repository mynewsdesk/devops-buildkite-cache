RSpec.describe BuildkiteCache do
  describe ".parse_configuration" do
    it "prefixes with organization and pipline and interpolates {{ filename }} to checksum of filename" do
      Dir.chdir "spec/dummy_environment" do
        configuration = BuildkiteCache.parse_configuration(%({
          "bundle-{{ 'Gemfile.lock' }}": "vendor/bundle",
          "node_modules-{{ 'yarn.lock' }}": "node_modules"
        }))

        expect(configuration.keys).to eq [
          "mynewsdesk/reponame/bundle-764146bde87b18d268c59eab70e73a87a6ce35ed",
          "mynewsdesk/reponame/node_modules-21b884ea474286a7c034d36f82c4c72f4a7be2d3",
        ]
      end
    end
  end
end
