# frozen_string_literal: true

require "octokit"
require "uri"
require "uri/ssh_git"

module Buildkite::Config
  class Repository
    def buildkite_repo
      ENV.fetch("BUILDKITE_REPO") { raise "Missing $BUILDKITE_REPO!" }
    end

    def github_repo
      if buildkite_repo.start_with?("git@")
        uri = URI::SshGit.parse(buildkite_repo)
        path = uri.path.gsub(/\.git$/, '')
        Octokit::Repository.new(path)
      else
        Octokit::Repository.from_url(buildkite_repo)
      end
    end
  end
end
