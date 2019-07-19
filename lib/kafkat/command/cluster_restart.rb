# frozen_string_literal: true

require 'kafkat/helpers/session'
require 'kafkat/helpers/cluster_restart'

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
        if Kafkat::Helpers::Session.exists?
          puts 'ERROR: A session is already started'
          puts "\n[Action] Please run 'next' or 'reset' commands"
          exit 1
        end

        print "Starting a new Cluster-Restart session.\n"

        @session = Kafkat::Helpers::Session.from_zookeepers(zookeeper)
        @session.save!

        puts "\n[Action] Please run 'next' to select the broker with lowest restarting cost"
      end

      def run_reset
        Kafkat::Helpers::Session.reset! if Session.exists?
        puts 'Session reset'
        puts "\n[Action] Please run 'start' to start the session"
      end

      def run_restore
        filename = arguments.last
        if Kafkat::Helpers::Session.exists?
          puts 'ERROR: A session is already started'
          puts "\n[Action] Please run 'next' or 'reset' commands"
          exit 1
        end

        @session = Kafkat::Helpers::Session.load!(file: filename)
        @session.save!
        puts 'Session restored'
        puts "\m[Action] Please run 'next' to select the broker with lowest restarting cost"
      end

      def run_next
        unless Kafkat::Helpers::Session.exists?
          puts 'ERROR: no session in progress'
          puts "\n[Action] Please run 'start' command"
          exit 1
        end

        @session = Kafkat::Helpers::Session.load!
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
            next_broker, = Kafkat::Helpers::ClusterRestart.select_broker_with_min_cost(session, @topics)
            @session.update_states!(Kafkat::Helpers::Session::STATE_PENDING, [next_broker])
            @session.save!
            puts "The next broker is: #{next_broker}"
          end
          puts "\n[Action-1] Restart broker #{next_broker} aka #{zookeeper.get_broker(next_broker).host}"
          puts "\n[Action-2] Run 'good #{next_broker}' to mark it as restarted."
        end
      end

      def run_log
        unless Kafkat::Helpers::Session.exists?
          puts 'ERROR: no session in progress'
          puts "\n[Action] Please run 'start' command"
          exit 1
        end

        @session = Kafkat::Helpers::Session.load!
        puts JSON.pretty_generate(@session.to_h)
      end

      def run_good
        broker_id = arguments.last
        unless Kafkat::Helpers::Session.exists?
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
        @session = Kafkat::Helpers::Session.load!
        begin
          if session.pending?(broker_id)
            session.update_states!(Kafkat::Helpers::Session::STATE_RESTARTED, [broker_id])
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
  end
end
