require 'colorize'

module GaussianParser
  module Cli
    ERROR_COLOR   = :red
    SUCCESS_COLOR = :green

    def print_as_error(message)
      puts "Error: #{message}".colorize(ERROR_COLOR)
    end

    def print_as_success(message)
      puts "#{message}".colorize(SUCCESS_COLOR)
    end
  end
end