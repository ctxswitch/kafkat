require 'mixlib/shellout'

module Kafkat
  module Interface
    class RunClassError < StandardError; end

    class RunClass
      attr_reader :command

      def initialize(run_class, run_script: 'kafka-run-class.sh')
        @zk_path = Kafkat::Config.zk_path
        @kafka_path = Kafkat::Config.kafka_path
        # Add a command timeout to the config sometime in the future
        # and add it to the shellout options at a later time.
        @run_script = run_script
        @run_class = run_class
      end

      def run!(*args)
        # This will need to be modified for the --bootstrap-server option once
        # we add in kafka versioning and context handling.
        args = args.unshift('--zookeeper', @zk_path)

        @command = "#{@kafka_path}/bin/#{@run_script} #{@run_class} #{args.join(' ')}"
        kafka_run_class = Mixlib::ShellOut.new(@command)
        kafka_run_class.run_command
        kafka_run_class.invalid!("Command failed: #{@command}") if kafka_run_class.error?
      rescue Errno::EACCES
        raise RunClassError, 'Permission denied.'
      rescue Errno::ENOENT
        raise RunClassError, 'Could not find the requested command.'
      rescue Mixlib::ShellOut::CommandTimeout
        raise RunClassError, 'Command timed out.'
      rescue Mixlib::ShellOut::ShellCommandFailed
        # For the kafka-run-class script, a error summary is written to stdout, so to
        # keep things concise, just output that... On debug (when we have debug) print
        # out the entire exception.
        raise RunClassError, kafka_run_class.stdout
      end
    end
  end
end
