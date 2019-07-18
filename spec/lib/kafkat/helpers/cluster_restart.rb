require 'spec_helper'
requrie 'kafkat/helpers/cluster_restart'
require 'kafkat/helpers/session'

describe Kafkat::Helpers::ClusterRestart do
  let(:p1) { Partition.new('topic1', 'p1', ['1', '2', '3'], '1', 1) }
  let(:p2) { Partition.new('topic1', 'p2', ['1', '2', '3'], '2', 1) }
  let(:p3) { Partition.new('topic1', 'p3', ['2', '3', '4'], '3', 1) }
  let(:topics) do
    {
      'topic1' => Topic.new('topic1', [p1, p2, p3]),
    }
  end
  let(:zookeeper) { double('zookeeper') }
  let(:broker_ids) { ['1', '2', '3', '4'] }

  describe '#get_broker_to_leader_partition_mapping' do
    it 'initialize a new mapping with 4 nodes' do
      broker_to_partition = ClusterRestart.get_broker_to_leader_partition_mapping(topics)

      expect(broker_to_partition['1']).to eq([p1])
      expect(broker_to_partition['2']).to eq([p2])
      expect(broker_to_partition['3']).to eq([p3])
      expect(broker_to_partition['4']).to eq([])
    end
  end

  describe '#calculate_costs' do
    context 'when no restarted brokers' do
      it do
        broker_to_partition = ClusterRestart.get_broker_to_leader_partition_mapping(topics)
        session = Session.from_brokers(broker_ids)

        expect(ClusterRestart.calculate_cost('1', broker_to_partition['1'], session)).to eq(3)
        expect(ClusterRestart.calculate_cost('2', broker_to_partition['2'], session)).to eq(3)
        expect(ClusterRestart.calculate_cost('3', broker_to_partition['3'], session)).to eq(3)
        expect(ClusterRestart.calculate_cost('4', broker_to_partition['4'], session)).to eq(0)
      end
    end

    context 'when one broker has been restarted' do
      it do
        broker_to_partition = ClusterRestart.get_broker_to_leader_partition_mapping(topics)
        session = Session.from_brokers(broker_ids)
        session.update_states!(Session::STATE_RESTARTED, ['4'])

        expect(ClusterRestart.calculate_cost('1', broker_to_partition['1'], session)).to eq(3)
        expect(ClusterRestart.calculate_cost('2', broker_to_partition['2'], session)).to eq(3)
        expect(ClusterRestart.calculate_cost('3', broker_to_partition['3'], session)).to eq(2)
        expect(ClusterRestart.calculate_cost('4', broker_to_partition['4'], session)).to eq(0)
      end
    end
  end

  describe '#select_broker_with_min_cost' do
    context 'when no restarted brokers' do
      it do
        session = Session.from_brokers(broker_ids)

        broker_id, cost = ClusterRestart.select_broker_with_min_cost(session, topics)
        expect(broker_id).to eq('4')
        expect(cost).to eq(0)
      end
    end

    context 'when next selection after one broker is restarted' do
      it do
        session = Session.from_brokers(broker_ids)
        session.update_states!(Session::STATE_RESTARTED, ['4'])

        broker_id, cost = ClusterRestart.select_broker_with_min_cost(session, topics)
        expect(broker_id).to eq('3')
        expect(cost).to eq(2)
      end
    end
  end
end
