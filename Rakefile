# frozen_string_literal: true

require_relative "lib/buildkite_config"

task :diff do
  diff = Buildkite::Config::Diff.new("pipeline-generate").compare
  puts diff.to_s(:color)

  pr = Buildkite::Config::PullRequest.new diff.to_s(:text)
  pr.update

  puts pr.body
end
