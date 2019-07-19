require 'spec_helper'
require 'kafkat/command/topic_verify'

describe Kafkat::Command::TopicVerify do
  let(:verify_replicas) { Kafkat::Command::TopicVerify.new }

  context 'two topics with replication factor 3' do
    let(:topic_rep_factor_three_with_four_replicas_in_partition1) do
      FactoryBot.build(:topic_rep_factor_three_with_four_replicas_in_partition1)
    end
    let(:topic2_rep_factor_three) { FactoryBot.build(:topic2_rep_factor_three) }

    it 'returns empty mismatched partitions for all brokers' do
      partition_replica_size, partition_replica_size_stat = verify_replicas.verify_replicas(
        nil,
        {
          "topic_name2" => topic2_rep_factor_three,
        }
      )

      expect(partition_replica_size).to eq({ "topic_name2" => { 0 => 3, 1 => 3, 2 => 3 } })
      expect(partition_replica_size_stat).to eq({ "topic_name2" => { 3 => 3 } })
    end

    it 'returns topic 1 partition 1 for all brokers' do
      partition_replica_size, partition_replica_size_stat = verify_replicas.verify_replicas(
        nil,
        {
          "topic_name1" => topic_rep_factor_three_with_four_replicas_in_partition1,
          "topic_name2" => topic2_rep_factor_three,
        }
      )

      expect(partition_replica_size)
        .to eq({ "topic_name1" => { 0 => 3, 1 => 4, 2 => 3 }, "topic_name2" => { 0 => 3, 1 => 3, 2 => 3 } })
      expect(partition_replica_size_stat).to eq({ "topic_name1" => { 3 => 2, 4 => 1 }, "topic_name2" => { 3 => 3 } })
    end

    it 'returns topic 1 partition 1 for broker 6' do
      partition_replica_size, partition_replica_size_stat = verify_replicas.verify_replicas(
        6,
        {
          "topic_name1" => topic_rep_factor_three_with_four_replicas_in_partition1,
          "topic_name2" => topic2_rep_factor_three,
        }
      )

      expect(partition_replica_size).to eq({ "topic_name1" => { 1 => 4 }, "topic_name2" => {} })
      expect(partition_replica_size_stat).to eq({ "topic_name1" => { 4 => 1 }, "topic_name2" => {} })
    end

    it 'returns empty mismatched partition for broker 3' do
      partition_replica_size, partition_replica_size_stat = verify_replicas.verify_replicas(
        3,
        {
          "topic_name1" => topic_rep_factor_three_with_four_replicas_in_partition1,
          "topic_name2" => topic2_rep_factor_three,
        }
      )

      expect(partition_replica_size).to eq({ "topic_name1" => {}, "topic_name2" => { 0 => 3, 1 => 3, 2 => 3 } })
      expect(partition_replica_size_stat).to eq({ "topic_name1" => {}, "topic_name2" => { 3 => 3 } })
    end
  end
end
