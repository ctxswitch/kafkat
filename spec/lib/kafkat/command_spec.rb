require 'spec_helper'

describe Kafkat::Command do
  before do
    stub_const 'OneCommandList', Class.new(Kafkat::Command::Base)
    OneCommandList.class_eval { register_as 'one_command_list' }
    OneCommandList.class_eval do
      def run
        puts 'one_command_list'
      end
    end
    stub_const 'OneCommandShow', Class.new(Kafkat::Command::Base)
    OneCommandShow.class_eval { register_as 'one_command_show' }
    OneCommandShow.class_eval do
      def run
        puts 'one_command_show'
      end
    end
    stub_const 'TwoCommandList', Class.new(Kafkat::Command::Base)
    TwoCommandList.class_eval { register_as 'two_command_list' }
    TwoCommandList.class_eval do
      def run
        puts 'two_command_list'
      end
    end
  end

  describe '#categories' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'returns unique categories' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
      ])
      expect(Kafkat::Command.categories).to eq(['one', 'two'])
    end
  end

  describe '#get_by_category' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'returns the requested category commands' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
      ])
      expect(Kafkat::Command.get_by_category('one')).to eq([OneCommandList, OneCommandShow])
    end

    it 'raises an error if the category does not have anything' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
      ])
      expect { Kafkat::Command.get_by_category('three') }.to raise_error(Kafkat::Command::NotFoundError)
    end
  end

  describe '#get' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'returns registered commands' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
      ])
      expect(Kafkat::Command.get('one_command_list')).to eq(OneCommandList)
      expect(Kafkat::Command.get('one_command_show')).to eq(OneCommandShow)
      expect(Kafkat::Command.get('two_command_list')).to eq(TwoCommandList)
    end
  end

  describe '#registered' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'appends to the registered list' do
      expect(Kafkat::Command.registered << { 'one' => {} }).to eq([{ 'one' => {} }])
      expect(Kafkat::Command.registered << { 'two' => {} }).to eq([{ 'one' => {} }, { 'two' => {} }])
    end
  end

  describe '#include?' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'return true for commands that are present' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: ['one-list', 'one'] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: ['two-list'] },
      ])
      expect(Kafkat::Command.include?('one_command_list')).to eq(true)
      expect(Kafkat::Command.include?('one_command_show')).to eq(true)
      expect(Kafkat::Command.include?('two_command_list')).to eq(true)
      expect(Kafkat::Command.include?('one')).to eq(true)
      expect(Kafkat::Command.include?('three_command_list')).to eq(false)
    end
  end

  describe '#deprecated?' do
    before(:each) do
      Kafkat::Command.reset
    end

    it 'return true for commands are deprecated' do
      allow(Kafkat::Command).to receive(:registered).and_return([
        { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: ['one-list', 'one'] },
        { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
        { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: ['two-list'] },
      ])
      expect(Kafkat::Command.deprecated?('one-list')).to eq(true)
      expect(Kafkat::Command.deprecated?('one')).to eq(true)
      expect(Kafkat::Command.deprecated?('two-list')).to eq(true)
    end
  end
end
