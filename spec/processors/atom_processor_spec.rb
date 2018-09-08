require 'rspec'
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../lib/gaussian_parser/processors/atom_processor')

RSpec.describe GaussianParser::Processors::AtomProcessor do
  let(:atom_data) do
    [
      '         1         33           0       -2.280632    2.669338   -0.574359',
      '         2         33           0        1.077846    1.968882   -0.934420',
      '         3         33           0        3.687837    0.155873    0.912135'
    ]
  end

  subject { described_class.new(atom_data) }

  describe '#process' do
    it 'process result' do
      results = subject.process

      expected_results = {
        '1' => 'As',
        '2' => 'As',
        '3' => 'As',
      }

      expect(results).to eq(expected_results)
    end
  end
end