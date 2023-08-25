module Buildkite
  module Config
    autoload :Annotate, File.expand_path("buildkite_config/annotate", __dir__)
    autoload :Diff, File.expand_path("buildkite_config/diff", __dir__)
    autoload :PullRequest, File.expand_path("buildkite_config/pull_request", __dir__)
    autoload :Repository, File.expand_path("buildkite_config/repository", __dir__)
  end
end
