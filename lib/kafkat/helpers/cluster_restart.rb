# frozen_string_literal: true

module Kafkat
  module Helpers
    class ClusterRestart
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
  end
end
