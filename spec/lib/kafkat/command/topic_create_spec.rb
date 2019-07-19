require 'kafkat/command/topic_create'

describe Kafkat::Command::TopicCreate do
  describe '.run' do
    context 'pass command to RunClass' do
      let(:command) { Kafkat::Command::TopicCreate.new }
      let(:args) { %w(test --partitions 2 --replicas 2) }

      it 'creates the appropriate command arguments' do
        allow_any_instance_of(Kafkat::Interface::RunClass).to receive(:run!).and_return(nil)
        command.parse_options(args)
        command.run
        expect(command.topic).to eq('test')
        expect(command.replication_factor).to eq(2)
        expect(command.partitions).to eq(2)
      end
    end
  end
end
