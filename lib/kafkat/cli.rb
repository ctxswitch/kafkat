# frozen_string_literal: true

module Kafkat
  class CLI
    attr_reader :config
    MERGEABLE_ARGS = [:zk_path, :log_path, :kafka_path]

    def self.run!(args)
      new.run(args)
    end

    def run(args)
      Command.load!

      # Get the category
      category_name = args.first

      # Get the subcommand
      subcommand_name = find_command_in_args(args)
      Command::Base.new.print_help_and_exit(1, category: category_name) if subcommand_name.nil?

      subcommand = Command.get(subcommand_name).new
      if Command.deprecated?(subcommand_name)
        puts "WARNING: The '#{subcommand_name}' command is deprecated, please use '#{subcommand.class.command_name.tr('_', ' ')}' instead."
      end

      args.shift(subcommand_name.split('_').size)
      subcommand.parse_options(args)

      # Load configuration
      if subcommand.config[:config_file]
        Config.load!(paths: [subcommand.config[:config_file]])
      else
        Config.load!
      end
      mergeable_options = subcommand.config.select do |key, value|
        MERGEABLE_ARGS.include?(key) && !value.nil?
      end
      Config.merge!(mergeable_options)

      subcommand.run

    rescue JSON::ParserError => e
      subcommand.print_error_and_exit("Could not parse configuration file: #{e}", 1)
    rescue Mixlib::Config::UnknownConfigOptionError => e
      subcommand.print_error_and_exit("Invalid configuration file: #{e}", 1)
    rescue Kafkat::Config::ParseError => e
      subcommand.print_error_and_exit(e, 1)
    rescue Kafkat::Config::NotFoundError => e
      subcommand.print_error_and_exit(e, 1)
    rescue OptionParser::InvalidOption
      subcommand.print_help_and_exit(1, category: category_name)
    rescue OptionParser::MissingArgument
      subcommand.print_help_and_exit(1, category: category_name)
    end

    def find_command_in_args(args)
      args = args.dup

      until args.empty?
        command = args.join('_').tr('-', '_')
        if Command.include?(command)
          return command
        else
          args.pop
        end
      end
      nil
    end
  end
end
