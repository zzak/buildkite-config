module Buildkite::Config
  class Annotate
    def initialize(diff)
      @diff = diff
    end

    def perform
      io = IO.popen("buildkite-agent annotate '#{plan}'")
      output = io.read
      io.close

      raise output unless $?.success?

      output
    end

    private
      def plan
        <<~PLAN
          ### :writing_hand: buildkite-config/plan

          <details>
          <summary>Show Output</summary>

          ```diff
          #{@diff.to_s}
          ```

          </details>
        PLAN
      end
  end
end