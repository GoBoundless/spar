module Spar

  class DirectiveProcessor < Sprockets::Processor

    include Spar::Helpers

    def evaluate(context, locals, &block)
      @result = data
      
      process_methods

      @result
    end

    protected
      
      def process_methods
        Spar.settings['interpolator_regex'] ||= '\[\{(.*?)\}\]' 
        @result.gsub!(/#{Spar.settings['interpolator_regex']}/) do
          command = $1.strip
          case command
          when /^path_to\((?<file_name>.*)\)$/
            path_to($~[:file_name])
          when /^javascript_include_tag\((?<file_names>.*)\)$/
            javascript_include_tag(*($~[:file_names]).split(',').map(&:strip))
          when /^stylesheet_link_tag\((?<file_names>.*)\)$/
            stylesheet_link_tag(*($~[:file_names]).split(',').map(&:strip))
          else
            variable = Spar.settings
            command.split('.').each { |key| variable = variable[key] }
            raise "Could not find a value for: '#{command}'" unless variable
            variable
          end
        end
      end

  end
end
