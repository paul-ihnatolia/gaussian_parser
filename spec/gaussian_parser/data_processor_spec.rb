require 'rspec'
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../lib/gaussian_parser/data_processor')

RSpec.describe GaussianParser::DataProcessor do
  let(:test_file_path) { File.join(File.dirname(__FILE__), '../data/1_Orpiment_As2S3_tHCTH_6-311G_3df.log') }
  let(:test_file) { File.open(test_file_path, 'r') }
  subject { described_class.new(test_file) }

  describe '#has_normal_termination?' do
    it 'returns true when "normal termination" found' do
      expect(subject.has_normal_termination?).to eq(true)
    end
  end
end