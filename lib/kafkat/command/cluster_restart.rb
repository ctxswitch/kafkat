# frozen_string_literal: true

module Kafkat
  module Command
    class ClusterRestart < Base
      attr_reader :session
      register_as 'cluster_restart'
      banner 'kafkat cluster restart'
      description 'Determine the server restart sequence for kafka'

      VALID_COMMANDS = %w(reset start next good log restore help).freeze

      def run
        subcommand_name = arguments.first || 'help'
        if VALID_COMMANDS.include?(subcommand_name)
          send(:"run_#{subcommand_name}")
        else
          print "ERROR: Unknown command #{subcommand_name}"
          run_help
        end
      end

      def run_help
        puts 'cluster restart help                Print Help and exit'
        puts 'cluster restart reset               Clean up the restart state'
        puts 'cluster restart start               Initialize the cluster-restart session for the cluster'
        puts 'cluster restart next                Calculate the next broker to restart based on the current state'
        puts 'cluster restart good <broker>       Mark this broker as successfully restarted'
        puts 'cluster restart log                 Print the state of the brokers'
        puts 'cluster restart restore <file>      Start a new session and restore the state defined in that file'
      end

      def run_start
        if Session.exists?
          puts 'ERROR: A session is already started'
          puts "\n[Action] Please run 'next' or 'reset' commands"
          exit 1
        end

        print "Starting a new Cluster-Restart session.\n"

        @session = Session.from_zookeepers(zookeeper)
        @session.save!

        puts "\n[Action] Please run 'next' to select the broker with lowest restarting cost"
      end

      def run_reset
        Session.reset! if Session.exists?
        puts 'Session reset'
        puts "\n[Action] Please run 'start' to start the session"
      end

      def run_restore
        file_name = arguments.last
        if Session.exists?
          puts 'ERROR: A session is already started'
          puts "\n[Action] Please run 'next' or 'reset' commands"
          exit 1
        end

        @session = Session.load!(file_name)
        @session.save!
        puts 'Session restored'
        puts "\m[Action] Please run 'next' to select the broker with lowest restarting cost"
      end

      def run_next
        unless Session.exists?
          puts 'ERROR: no session in progress'
          puts "\n[Action] Please run 'start' command"
          exit 1
        end

        @session = Session.load!
        if @session.all_restarted?
          puts 'All the brokers have been restarted'
        else
          pendings = @session.pending_brokers
          if pendings.size > 1
            puts 'ERROR Illegal state: multiple brokers are in Pending state'
            exit 1
          elsif pendings.size == 1
            next_broker = pendings[0]
            puts "Broker #{next_broker} is in Pending state"
          else
            @topics = zookeeper.topics
            next_broker, = ClusterRestartHelper.select_broker_with_min_cost(session, @topics)
            @session.update_states!(Session::STATE_PENDING, [next_broker])
            @session.save!
            puts "The next broker is: #{next_broker}"
          end
          puts "\n[Action-1] Restart broker #{next_broker} aka #{zookeeper.get_broker(next_broker).host}"
          puts "\n[Action-2] Run 'good #{next_broker}' to mark it as restarted."
        end
      end

      def run_log
        unless Session.exists?
          puts 'ERROR: no session in progress'
          puts "\n[Action] Please run 'start' command"
          exit 1
        end

        @session = Session.load!
        puts JSON.pretty_generate(@session.to_h)
      end

      def run_good
        broker_id = arguments.last
        unless Session.exists?
          puts 'ERROR: no session in progress'
          puts "\n[Action] Please run 'start' command"
          exit 1
        end

        if broker_id.nil?
          puts 'ERROR You must specify a broker id'
          exit 1
        end
        restart(broker_id)
        puts "Broker #{broker_id} has been marked as restarted"
        puts "\n[Action] Please run 'next' to select the broker with lowest restarting cost"
      end

      def restart(broker_id)
        @session = Session.load!
        begin
          if session.pending?(broker_id)
            session.update_states!(Session::STATE_RESTARTED, [broker_id])
            session.save!
          else
            puts "ERROR Broker state is #{session.state(broker_id)}"
            exit 1
          end
        rescue UnknownBrokerError => e
          puts "ERROR #{e}"
          exit 1
        end
      end
    end

    class UnknownBrokerError < StandardError; end
    class UnknownStateError < StandardError; end

    class ClusterRestartHelper
      def self.select_broker_with_min_cost(session, topics)
        broker_to_partition = get_broker_to_leader_partition_mapping(topics)
        broker_restart_cost = Hash.new(0)
        session.broker_states.each do |broker_id, state|
          if state == Session::STATE_NOT_RESTARTED
            current_cost = calculate_cost(broker_id, broker_to_partition[broker_id], session)
            broker_restart_cost[broker_id] = current_cost unless current_cost.nil?
          end
        end

        # Sort by cost first, and then broker_id
        broker_restart_cost.min_by { |broker_id, cost| [cost, broker_id] }
      end

      def self.get_broker_to_leader_partition_mapping(topics)
        broker_to_partitions = Hash.new { |h, key| h[key] = [] }

        topics.values.flat_map(&:partitions).each do |partition|
          broker_to_partitions[partition.leader] << partition
        end
        broker_to_partitions
      end

      def self.calculate_cost(broker_id, partitions, session)
        raise UnknownBrokerError, "Unknown broker #{broker_id}" unless session.broker_states.key?(broker_id)

        partitions.find_all { |partition| partition.leader == broker_id }
          .reduce(0) do |cost, partition|
          cost += partition.replicas.length
          cost -= partition.replicas.find_all { |replica| session.restarted?(replica) }.size
          cost
        end
      end
    end

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

      def self.load!(session_file = SESSION_PATH)
        path = File.expand_path(session_file)
        string = File.read(path)

        json = JSON.parse(string)
        new(json)
      rescue Errno::ENOENT
        raise NotFoundError
      rescue JSON::JSONError
        raise ParseError
      end

      def self.reset!(session_file = SESSION_PATH)
        path = File.expand_path(session_file)
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

      def save!(session_file = SESSION_PATH)
        File.open(File.expand_path(session_file), 'w') do |f|
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
