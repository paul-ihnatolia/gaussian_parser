require 'rspec'
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../lib/gaussian_parser/processors/results_processor')

RSpec.describe GaussianParser::Processors::ResultsProcessor do
  let(:results_data) do
    [
      '! R1    R(1,7)                  2.273          -DE/DX =    0.0                 !',
      '! R2    R(1,12)                 2.2968         -DE/DX =    0.0                 !'
    ]
  end

  subject { described_class.new(results_data) }

  describe '#process' do
    it 'process result' do
      results = subject.process

      expected_results = [
        ["R1", "R(1,7)", "2.273"],
        ["R2", "R(1,12)", "2.2968"]
      ]

      expect(results).to eq(expected_results)
    end
  end
end