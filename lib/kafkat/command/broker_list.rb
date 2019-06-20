# frozen_string_literal: true
module Kafkat
  module Command
    class BrokerList < Base
      register_as 'broker_list',
        deprecated: %w(brokers controller)
      # deprecated 'brokers'
      # deprecated 'controller'
      banner 'kafkat broker list'
      description 'List all of the brokers.'

      def run
        bs = zookeeper.brokers
        print_broker_header
        bs.each { |_, b| print_broker(b) }
        c = zookeeper.controller
        print "\nThe current controller is '#{c.id}' (#{c.host}:#{c.port}).\n\n"
      end
    end
  end
end
