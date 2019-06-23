require 'spec_helper'
require 'kafkat/command'

module Kafkat
  describe Command do
    before do
      stub_const 'OneCommandList', Class.new(Command::Base)
      OneCommandList.class_eval { register_as 'one_command_list' }
      OneCommandList.class_eval do
        def run
          puts 'one_command_list'
        end
      end
      stub_const 'OneCommandShow', Class.new(Command::Base)
      OneCommandShow.class_eval { register_as 'one_command_show' }
      OneCommandShow.class_eval do
        def run
          puts 'one_command_show'
        end
      end
      stub_const 'TwoCommandList', Class.new(Command::Base)
      TwoCommandList.class_eval { register_as 'two_command_list' }
      TwoCommandList.class_eval do
        def run
          puts 'two_command_list'
        end
      end
    end

    before(:each) do
      Command.reset
    end

    context 'categories' do
      it 'returns unique categories' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
        ])
        expect(Command.categories).to eq(['one', 'two'])
      end
    end

    context 'get_by_category' do
      it 'returns the requested category commands' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
        ])
        expect(Command.get_by_category('one')).to eq([OneCommandList, OneCommandShow])
      end

      it 'raises an error if the category does not have anything' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
        ])
        expect { Command.get_by_category('three') }.to raise_error(Kafkat::Command::NotFoundError)
      end
    end

    context 'get' do
      it 'returns registered commands' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: [] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: [] },
        ])
        expect(Command.get('one_command_list')).to eq(OneCommandList)
        expect(Command.get('one_command_show')).to eq(OneCommandShow)
        expect(Command.get('two_command_list')).to eq(TwoCommandList)
      end
    end

    context 'registered' do
      it 'appends to the registered list' do
        expect(Command.registered << { 'one' => {} }).to eq([{ 'one' => {} }])
        expect(Command.registered << { 'two' => {} }).to eq([{ 'one' => {} }, { 'two' => {} }])
      end
    end

    context 'include?' do
      it 'return true for commands that are present' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: ['one-list', 'one'] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: ['two-list'] },
        ])
        expect(Command.include?('one_command_list')).to eq(true)
        expect(Command.include?('one_command_show')).to eq(true)
        expect(Command.include?('two_command_list')).to eq(true)
        expect(Command.include?('one')).to eq(true)
        expect(Command.include?('three_command_list')).to eq(false)
      end
    end

    context 'deprecated?' do
      it 'return true for commands are deprecated' do
        allow(Command).to receive(:registered).and_return([
          { category: 'one', command: OneCommandList, id: 'one_command_list', deprecated: ['one-list', 'one'] },
          { category: 'one', command: OneCommandShow, id: 'one_command_show', deprecated: [] },
          { category: 'two', command: TwoCommandList, id: 'two_command_list', deprecated: ['two-list'] },
        ])
        expect(Command.deprecated?('one-list')).to eq(true)
        expect(Command.deprecated?('one')).to eq(true)
        expect(Command.deprecated?('two-list')).to eq(true)
      end
    end
  end
end
