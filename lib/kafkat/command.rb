# frozen_string_literal: true
require "mixlib/cli" unless defined?(Mixlib::CLI)

module Kafkat
  module Command
    class NotFoundError < StandardError; end
    class InvalidCommand < StandardError; end
    class InvalidArgument < StandardError; end

    def self.categories
      registered.uniq { |h| h[:category] }
        .map { |h| h[:category] }
    end

    def self.get_by_category(category)
      commands = registered.select { |h| h[:category] == category }
        .map { |h| h[:command] }
      raise NotFoundError if commands.empty?

      commands
    end

    def self.get(name)
      commands = registered.select { |h| h[:id] == name.downcase || h[:deprecated].include?(name) }
        .map { |h| h[:command] }
      raise NotFoundError if commands.empty?

      commands.first
    end

    def self.registered
      @registered ||= []
    end

    def self.include?(name)
      registered.map { |h| h[:id] }.include?(name)
    end

    def self.deprecated?(name)
      @deprecated ||= registered.map { |h| h[:deprecated] }.flatten
      @deprecated.include?(name)
    end

    def self.reset
      @registered = nil
    end

    def self.description
      @description ||= []
    end

    def self.subcommand_category(name)
      category_name = name&.tr('-', '_')
      return nil unless categories.include?(category_name)

      get_by_category(category_name)
    end

    def self.load!(force = false)
      return true if @loaded && !force
      files = Dir[File.expand_path('../command', __FILE__) + '/*.rb']
      files.each do |path|
        # set the stage for loading custom commands at runtime
        raise InvalidCommand unless Kernel.load(path)
      end
      @loaded = true
    end

    class Base
      include Mixlib::CLI
      include Formatting
      include CommandIO
      include Kafkat::Logging

      attr_reader :config

      class << self
        attr_reader :command_name
      end

      banner 'kafkat SUB-COMMAND (options)'

      option :help,
        short: "-h",
        long: "--help",
        description: "Show this message",
        on: :tail,
        boolean: true,
        show_options: true,
        exit: 0

      option :config_file,
        short: "-c",
        long: "--config CONFIG",
        description: "Configuration file to use."

      option :zk_path,
        short: '-z',
        long: '--zookeeper PATH',
        description: 'The zookeeper path string in the form <host>:<port>,...'

      option :log_path,
        short: '-l',
        long: '--log-path PATH',
        description: 'Where topic data is stored.'

      option :kafka_path,
        short: '-k',
        long: '--kafka-path PATH',
        description: 'Where kafka has been installed.'

      def self.register_as(name, deprecated: [])
        @command_name = name
        s = name.split('_')

        deprecated = deprecated.is_a?(Array) ? deprecated : [deprecated]
        Command.registered << {
          category: s.first,
          command: self,
          id: name,
          deprecated: deprecated,
        }
      end

      def self.description(desc)
        Command.description << desc
      end

      def print_category_banners(category)
        puts "-- #{category.upcase} COMMANDS --"
        Command.get_by_category(category).sort_by(&:command_name).each do |cmd|
          puts cmd.banner
        end
        puts
      end

      def print_help_and_exit(exitcode = 0, category: nil)
        puts "kafkat #{VERSION}: Simplified command-line administration for Kafka brokers\n\n"
        puts "#{opt_parser}\n"
        puts "Available subcommands: (for details, kafkat SUB-COMMAND --help)\n\n"

        if category.nil?
          Command.categories.sort.each do |cg|
            print_category_banners(cg)
          end
        else
          print_category_banners(category)
        end

        exit exitcode
      end

      def print_error_and_exit(msg, exitcode = 0)
        puts "#{msg}\n"
        exit exitcode
      end

      def run
        raise NotImplementedError
      end

      def arguments
        cli_arguments.dup
      end

      def admin
        @admin ||= begin
          Interface::Admin.new
        end
      end

      def zookeeper
        @zookeeper ||= begin
          Interface::Zookeeper.new
        end
      end

      def kafka_logs
        @kafka_logs ||= begin
          Interface::KafkaLogs.new
        end
      end
    end
  end
end
