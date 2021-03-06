require "gaussian_parser/cli"
require "gaussian_parser/processors/results_processor"
require "gaussian_parser/processors/atom_processor"

module GaussianParser
  class DataProcessor
    include Cli

    def initialize(file)
      @file_lines = file.readlines
    end

    def has_normal_termination?
      # programm terminates correctly when
      # "normal termination" line is found
      @file_lines.each do |line|
        if line =~ /Normal termination/
          return true
        end
      end
      return false
    end

    def parse
      processors = {}

      atom_count = {}
      molecular_orbitals = []
      harmonic_frequencies = []
      index = 0

      was_stationary_point = false
      was_standard_orientation = false
      was_mo_coefficients = false

      while index < @file_lines.length
        line = @file_lines[index]
        if line =~ /Stationary point found/ && !was_stationary_point
          print_as_success("Stationary point found")
          was_stationary_point = true
          index += 7
          results = []
          while @file_lines[index] =~ /^\s*!/
            results.push(@file_lines[index])
            index += 1
          end
          processors[:results_processor] = Processors::ResultsProcessor.new(results)
        end

        if line =~ /Standard orientation:/ && was_stationary_point
          unless was_standard_orientation
            print_as_usual("Standard orientation processing")
            was_standard_orientation = true
            index += 5
            atom_data = []
            while @file_lines[index] =~ /^(\s+\d+){3}/
              atom_data.push(@file_lines[index])
              index += 1
            end
            processors[:atom_processor] = Processors::AtomProcessor.new(atom_data)
          end
        end
        
        if line =~ /Molecular Orbital Coefficients/ && was_standard_orientation
          unless was_mo_coefficients
            print_as_usual("Molecular orbital processing")
            was_mo_coefficients = true
            mo_position = index + 1
            current_line = @file_lines[mo_position].split(/\s+/) 
            current_line.delete ""
            last_number = current_line.first.to_i - 1
            mo_regexp = generate_mo_regexp(last_number)
            while mo_position < @file_lines.length
              prev_zayniatist = nil
              if @file_lines[mo_position] =~ mo_regexp &&
                @file_lines[mo_position + 2] =~ /Eigenvalues --/                

                current_line = @file_lines[mo_position].split(/\s+/)
                last_number = current_line.last.to_i
                mo_regexp = generate_mo_regexp(last_number)
                current_line.delete ""
                energy_types = @file_lines[mo_position+=1].split(/\s+/)
                energy_types.delete ""
                energy_values = @file_lines[mo_position+=1].scan(/-*\d+\.*\d+/)
                energy_values.delete ""

                current_line.each_with_index do |elem,i|
                  symetry = energy_types[i].split('--').first.scan(/\w/).join
                  zayniatist = energy_types[i].split('--').last
                  prev_zayniatist ||= zayniatist
                  hartri = energy_values[i]
                  s = []
                  s << elem
                  s << symetry
                  s << hartri
                  s << hartri_to_ev(hartri) 
                  s << zayniatist
                  s << if prev_zayniatist != zayniatist
                    previous = molecular_orbitals.last
                    previous.pop()
                    previous.push "HOMO"
                    molecular_orbitals.pop()
                    molecular_orbitals.push(previous) 
                    "LUMO"
                  else
                    ""
                  end
                  prev_zayniatist = zayniatist
                  molecular_orbitals << s
                end
              end
              mo_position += 1
            end
          end
        end
        
        if line =~ /Harmonic frequencies/
          print_as_usual("Harmonic frequencies processing")
          index += 4
          current_line = @file_lines[index].split(/\s+/)
          current_line.delete ""
          last_number = current_line.first.to_i
          hf_regexp = /^\s+#{last_number}/
          while !(@file_lines[index] =~ /Thermochemistry/)
            if @file_lines[index] =~ hf_regexp
              harmonic_frequencies_data = []
              # save index position for return back 
              # if it is wrong line
              saved_position = index + 1
              # save current line for futher analyze
              saved_line = @file_lines[index]
              
              # Begin proccessing
              mode_numbers = @file_lines[index].split(/\s+/)
              mode_numbers.delete ""
              harmonic_frequencies_data << mode_numbers
              
              symmetries = @file_lines[index+=1].split(/\s+/)
              symmetries.delete ""
              harmonic_frequencies_data << symmetries

              poss_frequencies = @file_lines[index+=1].split(/ --\s+/)
              unless poss_frequencies.first =~ /Frequencies/
                index = saved_position
                next
              end
              frequencies = poss_frequencies.last.split(/\s+/)
              harmonic_frequencies_data << frequencies

              poss_red_masses = @file_lines[index+=1].split(/ --\s+/)
              unless poss_red_masses.first =~ /Red. masses/
                index = saved_position
                next
              end
              red_masses = poss_red_masses.last.split(/\s+/)
              harmonic_frequencies_data << red_masses

              poss_frc_consts = @file_lines[index+=1].split(/ --\s+/)
              unless poss_frc_consts.first =~ /Frc consts/
                index = saved_position
                next
              end
              frc_consts = poss_frc_consts.last.split(/\s+/)
              harmonic_frequencies_data << frc_consts

              poss_ir_inten = @file_lines[index+=1].split(/ --\s+/)
              unless poss_ir_inten.first =~ /IR Inten/
                index = saved_position
                next
              end
              ir_inten = poss_ir_inten.last.split(/\s+/)
              harmonic_frequencies_data << ir_inten

              poss_raman_activ = @file_lines[index+=1].split(/ --\s+/)
              unless poss_raman_activ.first =~ /Raman Activ/
                index = saved_position
                next
              end
              raman_activ = poss_raman_activ.last.split(/\s+/)
              harmonic_frequencies_data << raman_activ

              poss_depolar_p = @file_lines[index+=1].split(/ --\s+/)
              unless poss_depolar_p.first =~ /Depolar \(P\)/
                index = saved_position
                next
              end
              depolar_p = poss_depolar_p.last.split(/\s+/)
              harmonic_frequencies_data << depolar_p

              poss_depolar_u = @file_lines[index+=1].split(/ --\s+/)
              unless poss_depolar_u.first =~ /Depolar \(U\)/
                index = saved_position
                next
              end
              depolar_u = poss_depolar_u.last.split(/\s+/)
              harmonic_frequencies_data << depolar_u

              current_harmonic_position = harmonic_frequencies.size
              harmonic_frequencies_data[0].size.times do |i|
                harmonic_frequencies[current_harmonic_position + i] = []
                harmonic_frequencies_data.each do |el|
                  harmonic_frequencies[current_harmonic_position + i] << el[i]
                end
              end              
              
              # ex.  1                      2                      3
              # Split line with mode numbers
              current_line = saved_line.split(/\s+/)
              current_line.delete ""
              # Get last mode number for futher search
              last_number = current_line.last.to_i
              # next search for line that consists two neccessary numbers
              # separated with whitespace
              # TODO!
              hf_regexp = /^\s+#{last_number+=1}/
            end
            index += 1
          end
          break
        end

        index += 1
      end 
      return [
        processors[:results_processor].process,
        processors[:atom_processor].process,
        molecular_orbitals,
        harmonic_frequencies
      ]
    end

    def hartri_to_ev(hartri)
      to_ev = 27.2107
      (hartri.to_f * to_ev).round 6
    end

    def generate_mo_regexp(last_number)
      str = (1..2).to_a.inject('^') {|memo, e| memo += "\\s+#{last_number + e}"; memo }
      Regexp.new(str)
    end
  end
end