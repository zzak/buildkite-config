# frozen_string_literal: true

module Buildkite::Config
  module DSL
    class Agents
      attr_accessor :tags

      def initialize
        @tags = {
          queue: "default"
        }
      end

      def to_h
        @tags
      end
    end

    class Group
      attr_accessor :steps

      def initialize(name, &block)
        @name = name
        @steps = []
        instance_eval(&block) if block_given?
      end

      def step(command = nil, **args, &block)
        @steps << Step.new(command: command, **args, &block)
      end

      def to_h
        {}.tap do |hash|
          hash[:group] = @name
          hash[:steps] = @steps.map(&:to_h)
        end.deep_stringify_keys
      end
    end

    class Pipeline
      attr_accessor :steps

      def initialize
        @steps = []
        @groups = []
      end

      def group(name, &block)
        @groups << Group.new(name, &block)
      end

      def step(command = nil, **args, &block)
        @steps << Step.new(command: command, **args, &block)
      end

      def self.generate(&block)
        pipeline = new
        pipeline.instance_eval(&block)
        pipeline
      end

      def to_h
        @groups.collect(&:to_h)
      end
    end

    class Plugin
      def initialize(type, args)
        @type = type
        @attributes = args
      end

      def to_h
        { @type.to_sym => @attributes }
      end
    end

    class Retry
      def initialize(policy)
        @policy = {
          automatic: {
            exit_status: -1,
            limit: 2
          }
        }.deep_merge!(policy)
      end

      def to_h
        @policy
      end
    end

    class Step
      def initialize(command:, &block)
        @command = command
        instance_eval(&block) if block_given?
      end

      def optional_attributes
        @key = "optional-step"
        @label = "optional"
        @depends_on = "docker-image-ruby-3-2"
        @plugins = []
        @env = {}
        @timeout_in_minutes = 5
        @soft_fail = false
        @agents = Agents.new
        @artifact_paths = []
        @retry_policy = Retry.new({})
      end

      def label(label)
        @label = label
      end

      def key(key)
        @key = key
      end

      def depends_on(*dependencies)
        @depends_on = dependencies
      end

      def env(**attrs)
        @env ||= {}
        @env.merge!(**attrs)
      end

      def plugin(type, args)
        @plugins ||= []
        @plugins << Plugin.new(type, args)
      end

      def timeout_in_minutes(timeout)
        @timeout_in_minutes = timeout
      end

      def soft_fail(fail = true)
        @soft_fail = fail
      end

      def agents(**tags)
        @agents ||= Agents.new
        @agents.tags.merge!(**tags)
      end

      def artifact_paths(*paths)
        @artifact_paths ||= []
        @artifact_paths.concat(*paths)
      end

      def retry_policy(**policy)
        @retry_policy ||= Retry.new(policy)
      end

      def to_h
        {}.tap do |hash|
          hash[:command] = @command unless @command.nil?
          hash[:key] = @key if @key
          hash[:label] = @label if @label
          hash[:depends_on] = @depends_on if @depends_on
          hash[:plugins] = @plugins.collect(&:to_h) if @plugins
          hash[:env] = @env if @env
          hash[:timeout_in_minutes] = @timeout_in_minutes if @timeout_in_minutes
          hash[:soft_fail] = @soft_fail unless @soft_fail.nil?
          hash[:agents] = @agents.to_h if @agents
          hash[:artifact_paths] = @artifact_paths if @artifact_paths
          hash[:retry] = @retry_policy.to_h if @retry_policy
        end.deep_stringify_keys
      end
    end
  end
end
