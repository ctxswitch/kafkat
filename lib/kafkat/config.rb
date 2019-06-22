# frozen_string_literal: true
require 'mixlib/config' unless defined?(Mixlib::Config)

module Kafkat
  module Config
    class NotFoundError < StandardError; end
    class ParseError < StandardError; end

    extend Mixlib::Config
    config_strict_mode true
    default :zk_path, 'localhost:2181'
    default :log_path, '/kafka'
    default :kafka_path, '.'

    PATHS = [
      '/etc/kafkat/config.json',
      '~/.kafkat.json',
      '.kafkat.json',
    ].freeze

    def self.reset!
      # From Mixlib::Config
      reset
      # Reload
      @loaded = false
    end

    def self.load!
      return true if @loaded

      # Established order of precidence for right now just take the
      # last one, but in the future we will iterate through all of
      # them allowing overrides the closer you get to the working dir.
      configs = PATHS
        .map { |f| File.expand_path(f) }
        .select { |f| File.exist?(f) }

      raise NotFoundError if configs.empty?

      path = File.expand_path(configs.last)
      from_file(path)
      @loaded = true

    rescue Errno::EACCES
      raise ParseError, 'Permission denied'
    end
  end
end
