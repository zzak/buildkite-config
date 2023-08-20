# frozen_string_literal: true

require "buildkite_config"
require "test_helper"

class TestRepository < Minitest::Test
  def test_repository_buildkite_repo
    before_value = ENV["BUILDKITE_REPO"]
    ENV["BUILDKITE_REPO"] = "git@github.com:rails/rails.git"

    repo = Buildkite::Config::Repository.new

    assert_equal "git@github.com:rails/rails.git", repo.buildkite_repo

    ENV["BUILDKITE_REPO"] = before_value
  end

  def test_repository_buildkite_repo_raises
    before_value = ENV["BUILDKITE_REPO"]
    ENV["BUILDKITE_REPO"] = nil

    repo = Buildkite::Config::Repository.new

    error = assert_raises do
      repo.buildkite_repo
    end
    assert_equal "Missing $BUILDKITE_REPO!", error.message

    ENV["BUILDKITE_REPO"] = before_value
  end

  def test_repository_github_repo
    repo = Buildkite::Config::Repository.new

    repo.stub(:buildkite_repo, "https://github.com/rails/buildkite_config") do
      assert_kind_of Octokit::Repository, repo.github_repo
      assert_equal "rails", repo.github_repo.owner
      assert_equal "buildkite_config", repo.github_repo.name
    end

    repo.stub(:buildkite_repo, "git@github.com:rails/buildkite_config.git") do
      assert_kind_of Octokit::Repository, repo.github_repo
      assert_equal "rails", repo.github_repo.owner
      assert_equal "buildkite_config", repo.github_repo.name
    end
  end

  def test_repository_slug
    repo = Buildkite::Config::Repository.new

    repo.stub(:buildkite_repo, "https://github.com/rails/buildkite_config") do
      assert_equal "rails/buildkite_config", repo.github_repo.slug
    end

    repo.stub(:buildkite_repo, "git@github.com:rails/buildkite_config.git") do
      assert_equal "rails/buildkite_config", repo.github_repo.slug
    end
  end
end
