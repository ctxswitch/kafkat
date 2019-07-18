# frozen_string_literal: true

module Kafkat
  module Command
    class TopicVerify < Base
      register_as 'topic_verify', deprecated: 'verify-replicas'
      banner 'kafkat topic verify'
      description 'Check if all partitions in a topic have same number of replicas.'

      option :topics,
        short: '-T',
        long: '--topic TOPIC',
        description: 'The topics to verify.'

      option :brokers,
        short: '-B',
        long: '--brokers BROKERS',
        description: 'The destination brokers for the topics.'

      option :print_summary,
        long: '--print-summary',
        default: false,
        description: 'Show summary of mismatched partitions.'

      option :print_details,
        long: '--print-details',
        default: false,
        description: 'Show replica size of mismatched partitions.'

      def run
        topic_names = config[:topics]
        print_details = config[:print_details]
        print_summary = config[:print_summary]

        if topic_names
          topics_list = topic_names.split(',')
          topics = zookeeper.topics(topics_list)
        end
        topics ||= zookeeper.topics
        broker = config[:broker]&.to_i

        partition_replica_size, partition_replica_size_stat = verify_replicas(broker, topics)

        print_summary = !print_details || print_summary
        print_mismatched_partitions(partition_replica_size, partition_replica_size_stat, print_details, print_summary)
      end

      def verify_replicas(broker, topics)
        partition_replica_size = {}
        partition_replica_size_stat = {}

        topics.each do |_, t|
          partition_replica_size[t.name] = {}
          partition_replica_size_stat[t.name] = {}

          t.partitions.each do |p|
            replica_size = p.replicas.length

            if broker && !p.replicas.include?(broker)
              next
            end

            partition_replica_size_stat[t.name][replica_size] ||= 0
            partition_replica_size_stat[t.name][replica_size] += 1

            partition_replica_size[t.name][p.id] = replica_size
          end
        end

        [partition_replica_size, partition_replica_size_stat]
      end

      def print_mismatched_partitions(partition_replica_size, partition_replica_size_stat, print_details, print_summary)
        topic_column_width = partition_replica_size.keys.max_by(&:length).length
        if print_details
          printf "%-#{topic_column_width}s %-10s %-15s %-20s\n", 'topic', 'partition', 'replica_size', 'replication_factor'

          partition_replica_size.each do |topic_name, partition|
            replication_factor = partition_replica_size_stat[topic_name].key(partition_replica_size_stat[topic_name].values.max)

            partition.each do |id, replica_size|
              if replica_size != replication_factor
                printf "%-#{topic_column_width}s %-10d %-15d %-20d\n", topic_name, id, replica_size, replication_factor
              end
            end
          end
        end

        if print_summary
          printf "%-#{topic_column_width}s %-15s %-10s %-15s %-20s\n", 'topic', 'replica_size', 'count', 'percentage', 'replication_factor'
          partition_replica_size_stat.each do |topic_name, partition|
            next unless partition.values.size > 1

            replication_factor = partition_replica_size_stat[topic_name].key(partition_replica_size_stat[topic_name].values.max)
            num_partitions = 0.0
            partition.each { |_, value| num_partitions += value }

            partition.each do |replica_size, cnt|
              printf "%-#{topic_column_width}s %-15d %-10d %-15d %-20d\n", topic_name, replica_size, cnt, (cnt * 100 / num_partitions)
                .to_i, replication_factor
            end
          end
        end
      end
    end
  end
end
