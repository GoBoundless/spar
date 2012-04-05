require 'rbconfig'

if RUBY_VERSION < '1.9.2'
  desc = defined?(RUBY_DESCRIPTION) ? RUBY_DESCRIPTION : "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE})"
  abort <<-end_message

    Spar requires Ruby 1.9.2+.

    You're running
      #{desc}

    Please upgrade to continue.

  end_message
end
Signal.trap("INT") { puts; exit(1) }

require 'spar/version'

if ['--version', '-v'].include?(ARGV.first)
  puts "Spar #{Spar::VERSION}"
  exit(0)
end

if ARGV.first.nil?
  puts "Please specify a name for your new app like so: 'spar APP_NAME'"
  exit(0)
end

require 'spar/generators/application'

Spar::Generators::Application.new.generate(ARGV.first)