# frozen_string_literal: true

module Kafkat
  module Helpers
    class Session
      SESSION_PATH = '~/kafkat_cluster_restart_session.json'
      STATE_RESTARTED = 'restarted' # use String instead of Symbol to facilitate JSON ser/deser
      STATE_NOT_RESTARTED = 'not_restarted'
      STATE_PENDING = 'pending'
      STATES = [STATE_NOT_RESTARTED, STATE_RESTARTED, STATE_PENDING].freeze

      class NotFoundError < StandardError; end
      class ParseError < StandardError; end

      attr_reader :broker_states

      def self.exists?
        File.file?(File.expand_path(SESSION_PATH))
      end

      def self.load!(file: SESSION_PATH)
        path = File.expand_path(file)
        string = File.read(path)

        json = JSON.parse(string)
        new(json)
      rescue Errno::ENOENT
        raise NotFoundError
      rescue JSON::JSONError
        raise ParseError
      end

      def self.reset!(file: SESSION_PATH)
        path = File.expand_path(file)
        File.delete(path)
      end

      def self.from_zookeepers(zookeeper)
        broker_ids = zookeeper.broker_ids
        Session.from_brokers(broker_ids)
      end

      def self.from_brokers(brokers)
        states = brokers.each_with_object({}) { |id, h| h[id] = STATE_NOT_RESTARTED }
        Session.new('broker_states' => states)
      end

      def initialize(data = {})
        @broker_states = data['broker_states'] || {}
      end

      def save!(file: SESSION_PATH)
        File.open(File.expand_path(file), 'w') do |f|
          f.puts JSON.pretty_generate(to_h)
        end
      end

      def update_states!(state, ids)
        state = state.to_s if state.is_a?(Symbol)
        raise UnknownStateError, "Unknown State #{state}" unless STATES.include?(state)

        intersection = ids & broker_states.keys
        raise UnknownBrokerError, "Unknown brokers: #{(ids - intersection).join(', ')}" unless intersection == ids

        ids.each { |id| broker_states[id] = state }
        self
      end

      def state(broker_id)
        raise UnknownBrokerError, "Unknown broker: #{broker_id}" unless @broker_states.key?(broker_id)

        broker_states[broker_id]
      end

      def state?(broker_id, state)
        raise UnknownBrokerError, "Unknown broker: #{broker_id}" unless @broker_states.key?(broker_id)
        raise UnknownStateError, "Unknown state: #{state}" unless STATES.include?(state)

        @broker_states[broker_id] == state
      end

      def pending?(broker_id)
        state?(broker_id, STATE_PENDING)
      end

      def not_restarted?(broker_id)
        state?(broker_id, STATE_NOT_RESTARTED)
      end

      def restarted?(broker_id)
        state?(broker_id, STATE_RESTARTED)
      end

      def all_restarted?
        @broker_states.values.all? { |state| state == STATE_RESTARTED }
      end

      def pending_brokers
        broker_states.keys.find_all do |broker_id|
          broker_states[broker_id] == STATE_PENDING
        end
      end

      def to_h
        { broker_states: broker_states }
      end
    end
  end
end
