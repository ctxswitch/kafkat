module Kafkat
  module Command
    class TopicCreate < Base
      register_as 'topic_create'
      banner 'kafkat topic create TOPIC'
      description 'Create a new topic'

      option :replication_factor,
        short: '-R',
        long: '--replicas NUM',
        description: 'The number of replicas',
        default: 1,
        proc: Proc.new { |o| o.to_i }
      
      option :partitions,
        short: '-P',
        long: '--partitions NUM',
        descriptions: 'The number of partitions',
        default: 1,
        proc: Proc.new { |o| o.to_i }

      def run
        @topic = arguments.first
        @replication_factor = config[:replication_factor]
        @partitions = config[:partitions]

        cls = Kafkat::Interface::RunClass.new('kafka.admin.TopicCommand')
        args = [
          '--create',
          '--replication-factor', @replication_factor,
          '--partitions', @partitions,
          '--topic', @topic
        ]

        begin
          cls.run!(args)
        rescue Kafkat::Interface::RunClassError => e
          puts e
          exit 1
        end
      end
    end
  end
end
