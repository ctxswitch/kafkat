# frozen_string_literal: true
module Kafkat
  module Command
    class BrokerClean < Base
      register_as 'broker_clean'
      deprecated 'clean-indexes'
      banner 'kafkat broker clean'
      description 'Delete untruncated Kafka log indexes from the filesystem.'

      def run
        print "This operation will remove any untruncated index files.\n"
        return unless ask('Proceed (y/n)?')

        begin
          print "\nStarted.\n"
          count = kafka_logs.clean_indexes!
          print "\nDone (#{count} index file(s) removed).\n"
        rescue Interface::KafkaLogs::NoLogsError
          print "ERROR: Kakfa log directory doesn't exist.\n"
          exit 1
        rescue Interface::KafkaLogs::KafkaRunningError
          print "ERROR: Kafka is still running.\n"
          exit 1
        rescue => e
          print "ERROR: #{e}\n"
          exit 1
        end
      end
    end
  end
end
