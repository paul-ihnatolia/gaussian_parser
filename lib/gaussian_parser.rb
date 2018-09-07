require "gaussian_parser/version"
require "gaussian_parser/parser"

module GaussianParser
  def self.process(argv)
    GaussianParser::Parser.new(argv).process
  end
end
