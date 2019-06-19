# frozen_string_literal: true

module Kafkat
  class CLI
    attr_reader :config
    MERGEABLE_ARGS = [:zk_path, :log_path, :kafka_path]

    def self.run!(args)
      new.run(args)
    end

    def run(args)
      Command.load_all
      command_name = find_command_in_args(args)

      unless command_name
        if args.size > 1
          puts "Could not find subcommand for: #{args.join(' ')}\n"
          errorcode = 1
        else
          errorcode = 0
        end
        Command::Base.new.print_help_and_exit(errorcode)

        exit 1
      end

      # Warning for deprecated aliases
      if Command.deprecated.include?(command_name)
        puts "WARNING: The '#{command_name}' command is deprecated, please use '#{Command.deprecated[command_name].tr('_', ' ')}' instead."
      end
      command = Command.get(command_name).new
      command.invoked_as(command_name) # This should actually be in the initialize
      command.parse_options
      # This is where we could return an object if put into another method

      # Load configuration
      if command.config[:config_file]
        Config.load_file!(config[:config_file])
      else
        Config.load!
      end
      mergeable_options = command.config.select do |key, value|
        MERGEABLE_ARGS.include?(key) && !value.nil?
      end
      Config.merge!(mergeable_options)

      command.run

    rescue JSON::ParserError => e
      command.print_error_and_exit("Could not parse configuration file: #{e}", 1)
    rescue Mixlib::Config::UnknownConfigOptionError => e
      command.print_error_and_exit("Invalid configuration file: #{e}", 1)
    rescue OptionParser::InvalidOption
      command.print_help_and_exit(command, 1)
    rescue OptionParser::MissingArgument
      command.print_help_and_exit(command, 1)
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
  end
end
