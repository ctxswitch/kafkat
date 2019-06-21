describe Kafkat::Interface::RunClass do
  describe '#run!' do
    context 'when Mixlib::ShellOut fails' do
      let(:cls) { Kafkat::Interface::RunClass.new('stub') }

      it 'raises a run-class error on permission denied' do
        allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_raise(Errno::EACCES)
        expect { cls.run! }.to raise_error(Kafkat::Interface::RunClassError)
      end

      it 'raises a run-class error when the script is absent' do
        allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_raise(Errno::ENOENT)
        expect { cls.run! }. to raise_error(Kafkat::Interface::RunClassError)
      end

      it 'raises a run-class error on timeout' do
        allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
        expect { cls.run! }. to raise_error(Kafkat::Interface::RunClassError)
      end

      it 'raises a run-class error the command fails' do
        allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(self)
        allow_any_instance_of(Mixlib::ShellOut).to receive(:error?).and_return(true)
        expect { cls.run! }. to raise_error(Kafkat::Interface::RunClassError)
      end
    end
  end
end
