# Buildkite Cache

Plugin for buildkite to cache paths based on checksums.

Example configuration:
```yaml
plugins:
  - mynewsdesk/devops-buildkite-cache#master:
      configuration: >
        {
          "bundle-{{ checksum 'Gemfile.lock' }}": "vendor/bundle",
          "node_modules-{{ checksum 'yarn.lock' }}": "node_modules"
        }
```

Uses `tar` and `ssh` under the hood and expects `BUILDKITE_CACHE_URL` to be available on the agents to figure out which instance to connect to to fetch and store cached files. The URL should be in a simple `user@host` format.

Having `ruby` available on the agents is also a prerequisite.
