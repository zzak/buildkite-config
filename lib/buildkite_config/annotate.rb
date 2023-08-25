module Buildkite::Config
  class Annotate
    def initialize(diff)
      @diff = diff
    end

    def perform
      `buildkite-agent annotate '#{plan}'`
      #IO.popen("buildkite-agent annotate '#{plan}'")
    end

    private
      def plan
        <<~PLAN
          ### :writing_hand: buildkite-config/plan

          <details>
          <summary>Show Output</summary>

          ```diff
          #{@diff.to_s(:color)}
          ```

          </details>
        PLAN
      end
  end
end