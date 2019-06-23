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
      '.kafkat.json',
      '.kafkat.yml',
      '~/.kafkat.json',
      '~/.kafkat.yml',
      '/etc/kafkat/config.json',
      '/etc/kafkat/config.yml',
    ].freeze

    def self.load!
      return true if @loaded

      PATHS.each do |rel_path|
        path = File.expand_path(rel_path)
        next unless File.exist?(path)
        load_file!(path)
        @loaded = true
        break
      end
      raise NotFoundError unless @loaded
    rescue Errno::ENOENT
      raise NotFoundError
    end

    def self.load_file!(path)
      from_file(path)
    rescue Errno::ENOENT
      raise NotFoundError
    end
  end
end
