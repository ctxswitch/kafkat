# frozen_string_literal: true
module Kafkat
  module Command
    class TopicAlterReassign < Base
      register_as 'topic_alter_reassign'
      deprecated 'reassign'
      banner 'topic alter reassign TOPIC'
      description 'Begin reassignment of partitions.'

      option :replicas,
        short: '-R',
        long: '--replicas NUM',
        description: 'The number of replicas'

      option :brokers,
        short: '-B',
        long: '--brokers BROKERS',
        description: 'The destination brokers for alter'

      def run
        topic_names = arguments.last
        all_brokers = zookeeper.brokers

        topics = nil
        if topic_names
          topics_list = topic_names.split(',')
          topics = zookeeper.topics(topics_list)
        end
        topics ||= zookeeper.topics

        broker_ids = config[:brokers]&.split(',')&.map(&:to_i)
        replica_count = config[:replicas]

        broker_ids ||= zookeeper.brokers.values.map(&:id)

        all_brokers_id = all_brokers.values.map(&:id)
        broker_ids.each do |id|
          unless all_brokers_id.include?(id)
            print "ERROR: Broker #{id} is not currently active.\n"
            exit 1
          end
        end

        # *** This logic is duplicated from Kakfa 0.8.1.1 ***

        assignments = []
        broker_count = broker_ids.size

        topics.each do |_, t|
          # This is how Kafka's AdminUtils determines these values.
          # Partition count is not used.  Commenting now, removing later
          # partition_count = t.partitions.size
          topic_replica_count = replica_count || t.partitions[0].replicas.size

          if topic_replica_count > broker_count
            print "ERROR: Replication factor (#{topic_replica_count}) is larger than brokers (#{broker_count}).\n"
            exit 1
          end

          start_index = Random.rand(broker_count)
          replica_shift = Random.rand(broker_count)

          t.partitions.each do |p|
            replica_shift += 1 if p.id > 0 && p.id % broker_count == 0
            first_replica_index = (p.id + start_index) % broker_count

            replicas = [broker_ids[first_replica_index]]

            (0...topic_replica_count - 1).each do |i|
              shift = 1 + (replica_shift + i) % (broker_count - 1)
              index = (first_replica_index + shift) % broker_count
              replicas << broker_ids[index]
            end

            replicas.reverse!
            assignments << Assignment.new(t.name, p.id, replicas)
          end
        end

        # ****************

        prompt_and_execute_assignments(assignments)
      end
    end
  end
end
