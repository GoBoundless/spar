module Spar

  class DirectiveProcessor < Sprockets::Processor

    def evaluate(context, locals, &block)
      @result = data
      
      process_methods

      @result
    end

    protected
      
      def process_methods
        interpolator_regex = Spar.settings['interpolator_regex'] || '\[\{(.*?)\}\]' 
        @result.gsub!(/#{interpolator_regex}/) do
          command = $1.strip
          case command
          when /^path_to\((?<file_name>.*)\)$/
            Spar::Helpers.path_to($~[:file_name])
          when /^javascript_include_tag\((?<file_names>.*)\)$/
            Spar::Helpers.javascript_include_tag(*($~[:file_names]).split(',').map(&:strip))
          when /^stylesheet_link_tag\((?<file_names>.*)\)$/
            Spar::Helpers.stylesheet_link_tag(*($~[:file_names]).split(',').map(&:strip))
          else 
            if variable = Spar.settings[command]
              variable
            else
              raise "Could not find a value for: '#{command}'"
            end
          end
        end
      end

  end
end
