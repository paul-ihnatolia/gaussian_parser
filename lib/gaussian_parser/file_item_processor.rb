require "gaussian_parser/data_processor"
require "gaussian_parser/cli"

module GaussianParser
  class FileItemProcessor
    include Cli

    HEADERS_FOR_FILES = {
      'distances.dat'             =>  %w(No Distance Value Distances),
      'angles.dat'                =>  %w(No Angle Value Angles),
      'dihedrals.dat'             =>  %w(No Dihedral Value Dihedrals),
      'molecular_orbitals.dat'    =>  %w(No Symmetry Value_Hartree Value_eV Occupancy Homo/Lumo),
      'harmonic_frequencies.dat'  =>  ['No', 'Symmetry', 'Frequency', 'Red. mass', 'Frc const.', 'IR Intensity', 'Raman Activity', 'Depolar (P)', 'Depolar (U)']
    }

    def initialize(params)
      @output_path = params[:output_path]  
      @file_name = params[:file_name]
      @parser = DataProcessor.new(File.open(@file_name, 'r'))
    end
    
    def proccess
      print_as_usual("Checking for normal termination")
      if @parser.has_normal_termination?
        print_as_success("Normal termination found")
        print_as_usual("Checking for stationary point...")
        @stationary_point, @atom_count, 
        @molecular_orbitals, @harmonic_frequencies = @parser.parse
        if !@stationary_point.empty?    
          stp_results = {
            angles: [],
            dihedrals: [],
            distances: []
          }          
          
          # Sort results due to
          # their types
          @stationary_point.each do |rl|
            if rl[0][0] == 'R'
             stp_results[:distances].push rl
            elsif rl[0][0] == 'A'
              stp_results[:angles].push rl
            else
              stp_results[:dihedrals].push rl
            end
          end

          # Line format for output files
          line_format = "% -10s %15s %10s"
          
          # Change element format
          stp_results.each_value do |results|
            results.each do |result|
              change_element_format(result)
            end
          end

          # Create separate file for each type
          stp_results.each do |type, results|
            process_output_file(results, @output_path, 
                                "#{type.to_s}.dat", line_format)
          end
        else
          print_as_error("Stationary point was not found in #{@file_name}")
        end

        if !@molecular_orbitals.empty?
          line_format = "% -10s %2s %15s %15s %15s %10s"
          process_output_file(@molecular_orbitals, @output_path,
                              "molecular_orbitals.dat", line_format)
        else
          print_as_error("'Molecular Orbital Coefficients' line wasn't found!")
        end

        if !@harmonic_frequencies.empty?
          line_format = "% -5s %5s %15s %15s %15s %15s %15s %15s %15s"
          process_output_file(@harmonic_frequencies, @output_path,
                              "harmonic_frequencies.dat", line_format)
        else
          print_as_error("Error during harmonic frequencies analyze!")
        end
      else
        print_as_error("Normal termination was not found in #{@file_name}")
      end 
    end

    def change_element_format(line)
      element = line[1]
      # element
      #
      # L(13,15,18,30,-1)

      # TODO: make sure regexp is correct
      count = element.scan(/-?[0-9]+/)
      right_format = count.map! do |el|
        @atom_count[el].nil? ? "?(#{el})" : (@atom_count[el] + el)
      end
      line[1] = right_format.join("-")
      line
    end
    
    def process_output_file(results, file_path, file_name, line_format)
      File.open(File.join(file_path, file_name), "w") do |f|
        f.puts line_format % HEADERS_FOR_FILES[file_name] if HEADERS_FOR_FILES[file_name]
        f.puts
        results.each do |line|
          f.puts line_format % line
        end
      end
    end
  end
end