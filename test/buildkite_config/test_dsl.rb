# frozen_string_literal: true

require "buildkite_config"
require "minitest/autorun"

class TestDSL < Minitest::Test
  def test_pipeline_generate
    pipeline = Buildkite::Config::DSL::Pipeline.generate { }
    assert_equal [], pipeline.steps
  end

  def test_pipeline_generate_steps
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      step "ruby -v"
    end
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v")
    assert_equal step.to_h, pipeline.steps.first.to_h
  end

  def test_pipeline_generate_step_options
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      step "ruby -v" do
        plugin "docker", { image: "ruby:3.1" }
      end
    end

    step = Buildkite::Config::DSL::Step.new(command: "ruby -v") do
      plugin "docker", { image: "ruby:3.1" }
    end
    assert_equal step.to_h, pipeline.steps.first.to_h
  end

  def test_step_stringify_keys
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v")
    assert_equal(["command"], step.to_h.keys)
  end

  def test_step_defaults
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v")
    assert_equal({
      "command" => "ruby -v"
    }, step.to_h)
  end

  def test_step_optional_attributes_stringify_keys
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v") do
      optional_attributes
    end

    assert_equal(%w[
      command
      key
      label
      depends_on
      plugins
      env
      timeout_in_minutes
      soft_fail
      agents
      artifact_paths
      retry
    ], step.to_h.keys)

    assert_equal ["queue"], step.to_h["agents"].keys
    assert_equal ["exit_status", "limit"],
      step.to_h.try(:[], "retry").try(:[], "automatic").try(:keys)
  end

  def test_step_optional_attributes
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v") do
      optional_attributes
    end

    assert_equal({
      "command" => "ruby -v",
      "key" => "optional-step",
      "label" => "optional",
      "depends_on" => "docker-image-ruby-3-2",
      "plugins" => [],
      "env" => {},
      "timeout_in_minutes" => 5,
      "soft_fail" => false,
      "agents" => {
        "queue" => "default"
      },
      "artifact_paths" => [],
      "retry" => {
        "automatic" => {
          "exit_status" => -1,
          "limit" => 2
        }
      }
    }, step.to_h)
  end

  def test_step_custom_attributes
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v") do
      label "custom"
      depends_on "docker-image-ruby-3-1"
      env "RACK_VERSION": "~> 3.1"
      plugin "docker", { image: "ruby:3.1" }
      plugin "artifacts", download: ["workspace"]
      timeout_in_minutes 30
      soft_fail
      agents queue: "builder"
      artifact_paths ["artifacts"]
      retry_policy automatic: { limit: 5 }
    end

    assert_equal({
      "command" => "ruby -v",
      "label" => "custom",
      "depends_on" => ["docker-image-ruby-3-1"],
      "plugins" => [
        { "docker" => { "image" => "ruby:3.1" } },
        { "artifacts" => { "download" => ["workspace"] } }
      ],
      "env" => {
        "RACK_VERSION" => "~> 3.1"
      },
      "timeout_in_minutes" => 30,
      "soft_fail" => true,
      "agents" => {
        "queue" => "builder"
      },
      "artifact_paths" => ["artifacts"],
      "retry" => {
        "automatic" => {
          "exit_status" => -1,
          "limit" => 5
        }
      }
    }, step.to_h)
  end

  def test_step_soft_fail_false
    step = Buildkite::Config::DSL::Step.new(command: "ruby -v") do
      soft_fail false
    end

    assert_equal({
      "command" => "ruby -v",
      "soft_fail" => false
    }, step.to_h)
  end

  def test_pipeline_generate_step_map
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      ["2.7", "3.0", "3.1", "3.2"].map do |ruby|
        step do
          label ":docker: #{ruby}"
          key "docker-image-#{ruby}"
          plugin "artifacts", download: [".dockerignore", ".buildkite/*", ".buildkite/**/*"]
          plugin "docker-compose", {
            build: "base",
            config: ".buildkite/docker-compose.yml",
            env: ["PRE_STEPS", "RACK"],
            "image-name": ruby,
            "cache-from": ["zomg", "bbq"],
            push: ["base:#{ruby}", "base:#{ruby}-pr"],
            "image-repository": "base"
          }

          env "BUNDLER": "2.4"
          env "RUBYGEMS": "3.3"
          env "RUBY_IMAGE": ruby

          timeout_in_minutes 15
          agents queue: "builder"
        end
      end
    end

    assert_predicate pipeline.steps, :any?
    assert_equal ":docker: 2.7", pipeline.steps.first.to_h["label"]
    assert_equal "docker-image-2.7", pipeline.steps.first.to_h["key"]
    assert_equal [
      { "artifacts" =>
        { "download" => [".dockerignore", ".buildkite/*", ".buildkite/**/*"] }
      },
      { "docker-compose" =>
        {
          "build" => "base",
          "config" => ".buildkite/docker-compose.yml",
          "env" => ["PRE_STEPS", "RACK"],
          "image-name" => "2.7",
          "cache-from" => ["zomg", "bbq"],
          "push" => ["base:2.7", "base:2.7-pr"],
          "image-repository" => "base"
        }
      }
    ], pipeline.steps.first.to_h["plugins"]
  end

  def test_pipeline_generate_step_agents_tags
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      step do
        agents queue: "custom"
        agents ruby: "image"
        agents node: "v18", yarn: false
      end
    end

    assert_equal({
      "queue" => "custom",
      "ruby" => "image",
      "node" => "v18",
      "yarn" => false
    }, pipeline.steps.first.to_h["agents"])
  end

  def test_pipeline_generate_step_env_tags
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      step do
        env RUBY_VERSION: "3.2"
        env BUNDLER: "2.2", RUBYGEMS: "3.3"
      end
    end

    assert_equal({
      "RUBY_VERSION" => "3.2",
      "BUNDLER" => "2.2",
      "RUBYGEMS" => "3.3"
    }, pipeline.steps.first.to_h["env"])
  end

  def test_group_step
    group = Buildkite::Config::DSL::Group.new "isolated" do
      step "ruby -v"
    end

    assert_equal({
      "group" => "isolated",
      "steps" => [
        { "command" => "ruby -v" }
      ]
    }, group.to_h)
  end

  def test_pipeline_generate_group_step
    pipeline = Buildkite::Config::DSL::Pipeline.generate do
      group "isolated" do
        step "ruby -v"
      end
    end

    assert_equal([{
      "group" => "isolated",
      "steps" => [
        { "command" => "ruby -v" }
      ]
    }], pipeline.to_h)
  end
end
