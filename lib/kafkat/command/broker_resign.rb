# frozen_string_literal: true

module Kafkat
  module Command
    class BrokerResign < Base
      register_as 'broker_resign', deprecated: 'resign-rewrite'
      banner 'kafkat broker resign BROKER'
      description 'Shutdown a broker'

      option :force,
        long: '--force',
        default: false,
        description: 'Forcibly rewrite leaderships to exclude a broker.'

      option :ignore_isr,
        long: '--ignore-isr',
        default: false,
        description: 'Force rewrite as if there are no available ISRs.'

      def run
        broker_id = arguments.last
        if broker_id.nil?
          puts 'You must specify a broker ID.'
          exit 1
        end

        if config[:force]
          resign_forcefully(broker_id)
        else
          resign(broker_id)
        end
      end

      def resign(broker_id)
        print "This operation gracefully removes leaderships from broker '#{broker_id}'.\n"
        return unless agree('Proceed (y/n)?')

        result = nil
        begin
          print "\nBeginning shutdown.\n"
          result = admin.shutdown!(broker_id)
          print "Started.\n"
        rescue Interface::Admin::ExecutionFailedError
          print result
        end
      end

      def resign_forcefully(broker_id)
        print "This operation rewrites leaderships in ZK to exclude broker '#{broker_id}'.\n"
        print "WARNING: This is a last resort. Try without the force option first!\n\n".red

        return unless agree('Proceed (y/n)?')

        # Unused assignment.  Commenting for now, removing later.
        # brokers = zookeeper.brokers
        topics = zookeeper.topics
        ignore_isr = config[:ignore_isr]

        ops = {}
        topics.each do |_, t|
          t.partitions.each do |p|
            next if p.leader != broker_id

            alternates = p.isr.reject { |i| i == broker_id }
            new_leader_id = alternates.sample

            if !new_leader_id && !ignore_isr
              print "Partition #{t.name}-#{p.id} has no other ISRs!\n"
              exit 1
            end

            new_leader_id ||= -1
            ops[p] = new_leader_id
          end
        end

        print "\n"
        print "Summary of the new assignments:\n\n"

        print "Partition\tLeader\n"
        ops.each do |p, lid|
          print justify("#{p.topic_name}-#{p.id}")
          print justify(lid.to_s)
          print "\n"
        end

        begin
          print "\nStarting.\n"
          ops.each do |p, lid|
            retryable(tries: 3, on: Interface::Zookeeper::WriteConflictError) do
              zookeeper.write_leader(p, lid)
            end
          end
        rescue Interface::Zookeeper::WriteConflictError
          print "Failed to update leaderships in ZK. Try re-running.\n\n"
          exit 1
        end

        print "Done.\n"
      end
    end
  end
end
