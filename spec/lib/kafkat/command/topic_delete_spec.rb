require 'kafkat/command/topic_delete'

describe 'Kafkat::Command::TopicDelete' do
  describe '.run' do
    context 'pass the delete command to RunClass' do
      let(:command) { Kafkat::Command::TopicDelete.new }
      let(:args) { %w(test) }

      it 'creates the appropriate command arguments' do
        allow_any_instance_of(Kafkat::Interface::RunClass).to receive(:run!).and_return(nil)
        command.parse_options(args)
        command.run
        expect(command.topic).to eq('test')
      end
    end
  end
end
