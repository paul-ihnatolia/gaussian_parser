require 'gaussian_parser/utils/periodic_table'

module GaussianParser
  module Processors
    class AtomProcessor
      # raw_data
      #
      # ['         1         33           0       -2.280632    2.669338   -0.574359',
      #  '         2         33           0        1.077846    1.968882   -0.934420']

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def process
        @raw_data.inject({}) do |memo,line|
          atom_index, atom_periodic_number = line
            .split(/\s+/)
            .reject {|e| e == '' }[0..1]
          memo[atom_index] = Utils::PeriodicTable.symbol_by_periodic_number(atom_periodic_number)
          memo
        end
      end
    end
  end
end