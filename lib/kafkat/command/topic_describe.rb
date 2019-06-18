# frozen_string_literal: true
module Kafkat
  module Command
    class TopicDescribe < Base
      register_as 'topic_describe'
      deprecated 'partitions'
      banner 'topic describe TOPIC'
      description 'Print information about the given topic.'

      option :under_replicated,
        description: "Print topic partitions that are under-replicated.",
        long: "--under-replicated"

      option :unavailable,
        description: "Print topic partitions that are unavailable.",
        long: "--unavailable"

      def run
        topic_name = arguments.last
        topic_names = topic_name && [topic_name]

        brokers = zookeeper.brokers
        topics = zookeeper.topics(topic_names)

        print_partition_header
        topics.each do |_, t|
          t.partitions.each do |p|
            print_partition(p) if selected?(p, brokers)
          end
        end
      rescue Command::InvalidArgument
        puts "Please specify a topic(s)."
        print_help_and_exit(1)
      end

      private

      def selected?(partition, brokers)
        return partition.under_replicated? if only_under_replicated?
        return !partition.has_leader?(brokers) if only_unavailable?
        true
      end

      def only_under_replicated?
        !!config[:under_replicated]
      end

      def only_unavailable?
        !!config[:unavailable]
      end
    end
  end
end
