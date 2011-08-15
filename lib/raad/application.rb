# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

module Raad

  # The main execution class for Raad. This will execute in the at_exit
  # handler to run the server.
  class Application
    # Most of this stuff is straight out of sinatra.

    # Set of caller regex's to be skippe when looking for our API file
    CALLERS_TO_IGNORE = [ # :nodoc:
      /\/raad(\/(application))?\.rb$/, # all raad code
      /rubygems\/custom_require\.rb$/,    # rubygems require hacks
      /bundler(\/runtime)?\.rb/,          # bundler require hacks
      /<internal:/                        # internal in ruby >= 1.9.2
    ]

    # @todo add rubinius (and hopefully other VM impls) ignore patterns ...
    CALLERS_TO_IGNORE.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

    # Like Kernel#caller but excluding certain magic entries and without
    # line / method information; the resulting array contains filenames only.
    def self.caller_files
      caller_locations.map { |file, line| file }
    end

    # Like caller_files, but containing Arrays rather than strings with the
    # first element being the file, and the second being the line.
    def self.caller_locations
      caller(1).
        map    { |line| line.split(/:(?=\d|in )/)[0,2] }.
        reject { |file, line| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
    end

    # Find the app_file that was used to execute the application
    #
    # @return [String] The app file
    def self.app_file
      c = caller_files.first
      c = $0 if !c || c.empty?
      c
    end

    # Execute the application
    #
    # @return [Nil]
    def self.run!
      file = File.basename(app_file, '.rb')
      app = Object.module_eval(camel_case(file)).new

      runner = Raad::Runner.new(ARGV, app)
      puts(">> Raad service wrapper v#{VERSION} starting")
      runner.run
    end

    private

    # Convert a string to camel case
    #
    # @param str [String] The string to convert
    # @return [String] The camel cased string
    def self.camel_case(str)
      return str if str !~ /_/ && str =~ /[A-Z]+.*/

      str.split('_').map { |e| e.capitalize }.join
    end
  end

  at_exit do
    puts("$!=#{$!.inspect}, $0=#{$0.inspect}, app_file=#{Raad::Application.app_file.inspect}")
    if $!.nil? && $0 == Raad::Application.app_file
      Application.run!
    end
  end
end
