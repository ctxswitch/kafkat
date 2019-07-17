module Kafkat
  module Command
    class TopicDelete < Base
      register_as 'topic_delete'
      banner 'kafkat topic delete TOPIC'
      description 'Delete a topic'

      attr_reader :topic

      def run
        @topic = arguments.first

        cls = Kafkat::Interface::RunClass.new('kafka.admin.TopicCommand')
        args = [
          '--delete',
          '--topic', @topic,
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
