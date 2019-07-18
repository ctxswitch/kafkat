require 'spec_helper'

describe Kafkat::Helpers::Session do
  describe '.allBrokersRestarted?' do
    context 'when some brokers have not been restarted' do
      let(:session) do
        Session.new('broker_states' => { '1' => Session::STATE_NOT_RESTARTED, '2' => Session::STATE_RESTARTED })
      end

      it do
        expect(session.all_restarted?).to be false
      end
    end

    context 'when all brokers have been restarted' do
      let(:session) do
        Session.new('broker_states' => { '1' => Session::STATE_RESTARTED, '2' => Session::STATE_RESTARTED })
      end

      it do
        expect(session.all_restarted?).to be true
      end
    end
  end

  describe '.update_states!' do
    let(:session) do
      Session.new('broker_states' => { '1' => Session::STATE_NOT_RESTARTED, '2' => Session::STATE_RESTARTED })
    end

    it 'validates state' do
      expect { session.update_states!('my_state', []) }.to raise_error UnknownStateError
    end

    it 'validates broker ids' do
      expect { session.update_states!(Session::STATE_RESTARTED, ['1', '4']) }.to raise_error UnknownBrokerError
    end

    it 'changes the states' do
      session.update_states!(Session::STATE_PENDING, ['1'])
      expect(session.broker_states['1']).to eql(Session::STATE_PENDING)
    end
  end
end
