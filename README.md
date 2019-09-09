# Buildkite Cache

Plugin for buildkite to cache paths based on checksums.

By default it will cache:
- rubygems from `vendor/bundle` keyed with ruby version and checksums `Gemfile.lock` checksum
- npm packages from `node_modules`  node version checksums from  and `yarn.lock`

It will also cache the master branches as fallback for situations where no exact checksun match is found.

If you need to add additional caching of non conventional files you can pass cache keys and paths as a json payload in your `pipeline.yml`.

Example configuration:
```yaml
plugins:
  - mynewsdesk/devops-buildkite-cache#master:
      configuration: >
        {
          "php-libraries-{{ composer.lock }}": "vendor",
        }
```

Uses `tar` and `ssh` under the hood and expects `BUILDKITE_CACHE_URL` to be available on the agents to figure out which instance to connect to to fetch and store cached files. The URL should be in a simple `user@host` format.

Having `ruby` available on the agents is also a prerequisite.
