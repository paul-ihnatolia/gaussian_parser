require "gaussian_parser/cli"
require "gaussian_parser/file_item_processor"

module GaussianParser
  class Parser
    include Cli

    def initialize(argv = {})
      @params  = argv[:params] || {}
      @options = argv[:options] || {}
    end

    def get_file_path_from_current_dir path
      File.join(Dir.pwd, path)
    end

    def get_output_directory_path
      get_file_path_from_current_dir("output")
    end

    def create_folder_if_not_exist folder_path
      unless Dir.exist? folder_path
        print_as_success("Creating #{folder_path}")
        Dir.mkdir(folder_path)
      end
      folder_path
    end

    def process
      if @params.length > 0
        output_base_path = get_file_path_from_current_dir(create_folder_if_not_exist("output"))
        
        @params.each do |file_name|
          print_as_usual("Try to process #{file_name}")
          if File.exist?(file_name)
            base_file_name = File.basename(File.basename(file_name), ".out.txt")
            file_output_folder = create_folder_if_not_exist(File.join(output_base_path, base_file_name))
            params = {
              output_path: file_output_folder,
              file_name: file_name 
            }
            FileItemProcessor.new(params).proccess
          else
            print_as_error "'#{file_name}' doesn't exist or it is not a valid file"
          end      
        end
      else
        print_as_error "Unspecified input data"
      end
    end
  end
end