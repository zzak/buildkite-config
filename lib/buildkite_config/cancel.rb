# frozen_string_literal: true

module Buildkite::Config
  class Cancel
    def initialize(org, pipeline)
      @client = Buildkit.new(token: buildkite_token)
      @org = org
      @pipeline = pipeline
    end

    # Make sure your BUILDKITE_TOKEN has `write_pipelines` scope
    def cancel_pipeline_builds
      each_build do |build|
        next unless ["running", "scheduled"].include? build.state
        @client.cancel_build(@org, @pipeline, build.number)
      rescue => error
        puts "Skipping #{@org}/#{@pipeline}##{build.number}: #{error.class}"
      end
    end

    private
      def buildkite_token
        ENV.fetch("BUILDKITE_TOKEN") {
          raise "BUILDKITE_TOKEN undefined!\nMake sure your BUILDKITE_TOKEN has `write_pipelines` scope too!"
        }
      end

      def each_build(&block)
        pipeline = @client.pipeline(@org, @pipeline)
        response = pipeline.rels[:builds].get
        loop do
          response.data.each(&block)
          return unless response.rels[:next]
          response = response.rels[:next].get
        end
      end
  end
end
