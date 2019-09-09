RSpec.describe BuildkiteCache do
  describe ".generate_configuration" do
    context "in an environment using both ruby and node" do
      around do |example|
        Dir.chdir "spec/dummy_environment" do
          example.run
        end
      end

      it "adds caching for vendor/bundle and node_modules" do
        configuration = BuildkiteCache.generate_configuration

        expect(configuration).to eq(
          "mynewsdesk/reponame/bundle-2.6.4-764146bde87b18d268c59eab70e73a87a6ce35ed" => "vendor/bundle",
          "mynewsdesk/reponame/node_modules-10.16.3-21b884ea474286a7c034d36f82c4c72f4a7be2d3" => "node_modules",
        )
      end

      context "when given explicit configuration" do
        it "adds keys based on {{ filename }} checksums" do
          configuration = BuildkiteCache.generate_configuration(%({
            "php-libs-{{ composer.lock }}": "vendor/php"
          }))

          expect(configuration).to include(
            "mynewsdesk/reponame/php-libs-5ce26da5d78c203ca85e6894614c29d6aea60f75" => "vendor/php",
          )
        end
      end

      context "when given explicit configuration with a non existing file" do
        it "raises an exception" do
          config = %({
            "foo-{{ non-existing.lock }}": "foo/bar"
          })

          expect { BuildkiteCache.generate_configuration(config) }.to raise_error(Errno::ENOENT)
        end
      end
    end

    context "in a node only environment" do
      around do |example|
        Dir.chdir "spec/dummy_environment-nvm-only" do
          example.run
        end
      end

      it "adds caching of node_modules" do
        configuration = BuildkiteCache.generate_configuration

        expect(configuration).to eq(
          "mynewsdesk/reponame/node_modules-10.10.1-21b884ea474286a7c034d36f82c4c72f4a7be2d3" => "node_modules",
        )
      end
    end
  end
end
