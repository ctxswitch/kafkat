# frozen_string_literal: true

module Kafkat
  class CLI
    attr_reader :config

    def self.run!
      new.run
    end

    def run
      Command.load_all
      command_name = find_command_in_args(ARGV)

      unless command_name
        puts "Could not find subcommand for: #{ARGV.join(' ')}\n"
        Command.list_commands
        exit 1
      end

      # Warning for deprecated aliases
      if Command.deprecated.include?(command_name)
        puts "WARNING: The '#{command_name}' command is deprecated, please use '#{Command.deprecated[command_name].tr('_', ' ')}' instead."
      end
      command = Command.get(command_name).new
      command.invoked_as(command_name)
      command.run

    rescue OptionParser::InvalidOption
      command.print_help_and_exit
    rescue OptionParser::MissingArgument
      command.print_help_and_exit
    end

    def find_command_in_args(args)
      args = args.dup
      until args.empty?
        command = args.join('_').tr('-', '_')
        if Command.all.key?(command)
          return command
        else
          args.pop
        end
      end
      nil
    end

    def print_banner
      # print "kafkat #{VERSION}: Simplified command-line administration for Kafka brokers\n"
      # print "usage: kafkat [command] [options]\n"
    end

    def print_commands
      # print "\nHere's a list of supported commands:\n\n"
      # Command.all.values.sort_by(&:command_name).each do |klass|
      #   klass.usages.each do |usage|
      #     format = usage[0]
      #     description = usage[1]
      #     padding_length = 68 - format.length
      #     padding = ' ' * padding_length unless padding_length.negative?
      #     print "  #{format}#{padding}#{description}\n"
      #   end
      # end
      # print "\n"
    end

    def no_command_error
      print "This command isn't recognized.\n"
      print_commands
      exit 1
    end
  end
end
