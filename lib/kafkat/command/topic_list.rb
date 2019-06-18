# frozen_string_literal: true
module Kafkat
  module Command
    class TopicList < Base
      register_as 'topic_list'
      deprecated 'topics'
      banner 'topic list'
      description 'List all topics.'

      def run
        topic_names = zookeeper.topic_names

        topic_names.each { |name| print_topic_name(name) }
      end
    end
  end
end
