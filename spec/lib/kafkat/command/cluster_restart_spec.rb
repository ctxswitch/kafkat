require 'spec_helper'
require 'kafkat/command/cluster_restart'
require 'kafkat/helpers/cluster_restart'
require 'kafkat/helpers/session'

describe Kafkat::Command::ClusterRestart do
  let(:p1) { Kafkat::Partition.new('topic1', 'p1', ['1', '2', '3'], '1', 1) }
  let(:p2) { Kafkat::Partition.new('topic1', 'p2', ['1', '2', '3'], '2', 1) }
  let(:p3) { Kafkat::Partition.new('topic1', 'p3', ['2', '3', '4'], '3', 1) }
  let(:topics) do
    {
      'topic1' => Kafkat::Topic.new('topic1', [p1, p2, p3]),
    }
  end
  let(:zookeeper) { double('zookeeper') }
  let(:broker_ids) { ['1', '2', '3', '4'] }
  let(:broker_4) { Kafkat::Broker.new('4', 'i-xxxxxx.inst.aws.airbnb.com', 9092) }
  let(:session) { Kafkat::Helpers::Session.from_brokers(broker_ids) }

  around(:all) do |example|
    prev_home = ENV['HOME']
    tmp = Dir.mktmpdir
    ENV['HOME'] = tmp
    begin
      example.run
    ensure
      FileUtils.rm_rf tmp
      ENV['HOME'] = prev_home
    end
  end

  describe '.run_next' do
    let(:command) { Kafkat::Command::ClusterRestart.new }

    it 'execute next with 4 brokers and 3 partitions' do
      allow(zookeeper).to receive(:broker_ids).and_return(broker_ids)
      allow(zookeeper).to receive(:get_broker).and_return(broker_4)
      allow(zookeeper).to receive(:topics).and_return(topics)
      allow(Kafkat::Helpers::Session).to receive(:exists?).and_return(true)
      allow(Kafkat::Helpers::Session).to receive(:load!).and_return(session)
      allow(session).to receive(:save!)
      allow(command).to receive(:zookeeper).and_return(zookeeper)

      expect(Kafkat::Helpers::Session).to receive(:load!)
      expect(session).to receive(:save!)

      command.run_next
      expect(command.session.broker_states['4']).to eq(Kafkat::Helpers::Session::STATE_PENDING)
    end

    describe '.run_good' do
      let(:command) { Kafkat::Command::ClusterRestart.new }
      let(:session) do
        Kafkat::Helpers::Session.new('broker_states' => { '1' => Kafkat::Helpers::Session::STATE_PENDING })
      end

      it 'set one broker to be restarted' do
        allow(Kafkat::Helpers::Session).to receive(:exists?).and_return(true)
        allow(Kafkat::Helpers::Session).to receive(:load!).and_return(session)
        allow(session).to receive(:save!)

        # expect(Session).to receive(:load!)
        expect(session).to receive(:save!)
        command.restart('1')
        expect(command.session.broker_states['1']).to eq(Kafkat::Helpers::Session::STATE_RESTARTED)
      end
    end
  end
end
