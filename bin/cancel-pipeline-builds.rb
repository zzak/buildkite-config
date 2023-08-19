#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require_relative "../lib/buildkite_config"
require_relative "../lib/buildkite_config/cancel"

require "buildkit"

Buildkite::Config::Cancel.new(ARGV.shift, ARGV.shift).cancel_pipeline_builds
