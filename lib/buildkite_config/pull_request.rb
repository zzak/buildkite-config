require "octokit"

module Buildkite::Config
  class PullRequest
    PLAN_FORM = /<!-- buildkite-config\/plan:begin -->(.*)<!-- buildkite-config\/plan:end -->/m

    def initialize(diff)
      @diff = diff
      @github = Octokit::Client.new(auto_paginate: true, access_token: github_token)
      @pull_request = fetch_pr
    end

    def update
      resp = @github.update_pull_request("zzak/buildkite-config", pr_number, body: updated_body)
      puts resp.inspect
    end

    def body
      @pull_request.body
    end

    private
      def fetch_pr
        @github.pull_request(github_pull_request_repo, pr_number)
      end

      def github_pull_request_repo
        @repo ||= Octokit::Repository.from_url(
          ENV.fetch("BUILDKITE_PULL_REQUEST_REPO") { raise "Not a PR." })
        @repo.slug.gsub(/\.git$/, '')
      end

      def github_token
        ENV.fetch("GITHUB_TOKEN") { raise "Missing $GITHUB_TOKEN!" }
      end

      def pr_number
        ENV.fetch("BUILDKITE_PULL_REQUEST") { raise "Skipping: Not a pull request\nMissing $BUILDKITE_PULL_REQUEST!" }
      end

      def updated_body
        PLAN_FORM.match?(body) ?
          @pull_request.body.gsub!(PLAN_FORM, plan) :
          @pull_request.body.nil? ? "" << plan : @pull_request.body << plan
      end

      def plan
        <<~PLAN

          <!-- buildkite-config/plan:begin -->

          ---

          ### :writing_hand: buildkite-config/plan

          <details>
          <summary>Show Output</summary>

          ```diff
          #{@diff}
          ```

          </details>

          <!-- buildkite-config/plan:end -->
        PLAN
      end
  end
end