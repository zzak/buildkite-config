# frozen_string_literal: true

Buildkite::Builder.pipeline do
  require "buildkite_config"
  use Buildkite::Config::BuildContext
  use Buildkite::Config::DockerBuild
  use Buildkite::Config::RakeCommand
  use Buildkite::Config::RubyGroup

  plugin :docker_compose, "docker-compose#v4.16.0"
  plugin :artifacts, "artifacts#v1.9.3"

  build_context.setup_rubies %w(3.3)

  group do
    label "build"
    build_context.rubies.each do |ruby|
      builder ruby, compose: {
        "cli_version": "2",
        "image-name": "buildkite_base",
        "cache-from": ["buildkite_base"],
        "push": "",
        "image-repository": "",
      }
    end
  end

  build_context.rubies.each do |ruby|
    ruby_group ruby do
      # ActionCable and ActiveJob integration tests
      rake "actioncable", task: "test:integration && echo $$? && exit 3", retry_on: [{ exit_status: -1, limit: 3 }, { exit_status: 3, limit: 2 }, soft_fail: { exit_status: 3 }, compose: {
        "cli_version": "2",
        "pull": "",
      }, env: {
        "IMAGE_NAME": "buildkite_base",
      }
    end
  end
end
