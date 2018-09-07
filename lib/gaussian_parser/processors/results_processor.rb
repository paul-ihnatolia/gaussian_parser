module GaussianParser
  module Processors
    class ResultsProcessor
      # results
      #
      # ['! R1    R(1,7)                  2.273          -DE/DX =    0.0                 !',
      #  '! R2    R(1,12)                 2.2968         -DE/DX =    0.0                 !',
      #  '! R3    R(1,13)                 2.2494         -DE/DX =    0.0                 !']
      #
      def initialize(results_raw)
        @results_raw = results_raw
      end

      def process
        @results_raw.map do |line|
          line.gsub!(/\s*!\s*/,'')
          line.split(/\s+/)[0..2]
        end
      end
    end
  end
end