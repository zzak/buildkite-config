require "diffy"

module Buildkite::Config
  module Diff
    def self.compare
      head = generated_pipeline(".")
      main = generated_pipeline("tmp/buildkite-config")
      Diffy::Diff.new(main, head, allow_empty_diff: false, context: 4)
    end

    def self.generated_pipeline(repo)
      Dir.mktmpdir do |dir|
        IO.popen "ruby #{repo}/pipeline-generate tmp/rails > #{dir}/pipeline"
        File.read("#{dir}/pipeline")
      end
    end
  end
end