require 'json'

describe Kafkat::Config do
  describe '.load!' do
    before(:each) do
      Kafkat::Config.reset!
    end

    context 'invalid config files' do
      it 'raises an error if no files are present' do
        allow(File).to receive(:exist?).and_return(false)
        expect { Kafkat::Config.load! }.to raise_error(Kafkat::Config::NotFoundError)
      end

      it 'raises an error if incorrect permissions' do
        allow(File).to receive(:exist?).and_return(true)
        allow(IO).to receive(:read).and_raise(Errno::EACCES)
        expect { Kafkat::Config.load! }.to raise_error(Kafkat::Config::ParseError)
      end
    end

    context 'config file precedence' do
      let(:etc_kafkat_config) do
        JSON.generate({
          kafka_path: '/opt/kafka-1',
          zk_path: 'localhost:2181',
          log_path: '/kafka-1',
        })
      end
      let(:home_kafka) do
        JSON.generate({
          kafka_path: '/opt/kafka-2',
          zk_path: 'localhost:2182',
          log_path: '/kafka-2',
        })
      end
      let(:cwd_kafka) do
        JSON.generate({
          kafka_path: '/opt/kafka-3',
          zk_path: 'localhost:2183',
          log_path: '/kafka-3',
        })
      end
      let(:custom_kafka) do
        JSON.generate({
          kafka_path: '/opt/kafka-4',
          zk_path: 'localhost:2184',
          log_path: '/kafka-4',
        })
      end

      it 'loads /etc/kafkat/config.json' do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with('/etc/kafkat/config.json').and_return(true)
        # Mixlib::Config uses IO.read
        allow(IO).to receive(:read).and_raise(Errno::EACCES)
        allow(IO).to receive(:read).with('/etc/kafkat/config.json').and_return(etc_kafkat_config)

        Kafkat::Config.load!
        expect(Kafkat::Config.kafka_path).to eq('/opt/kafka-1')
        expect(Kafkat::Config.zk_path).to eq('localhost:2181')
        expect(Kafkat::Config.log_path).to eq('/kafka-1')
      end

      it 'loads ~/.kafkat.json' do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(File.expand_path('~/.kafkat.json')).and_return(true)
        # Mixlib::Config uses IO.read
        allow(IO).to receive(:read).and_raise(Errno::EACCES)
        allow(IO).to receive(:read).with(File.expand_path('~/.kafkat.json')).and_return(home_kafka)

        Kafkat::Config.load!
        expect(Kafkat::Config.kafka_path).to eq('/opt/kafka-2')
        expect(Kafkat::Config.zk_path).to eq('localhost:2182')
        expect(Kafkat::Config.log_path).to eq('/kafka-2')
      end

      it 'loads .kafkat.json' do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(File.expand_path('.kafkat.json')).and_return(true)
        # Mixlib::Config uses IO.read
        allow(IO).to receive(:read).and_raise(Errno::EACCES)
        allow(IO).to receive(:read).with(File.expand_path('.kafkat.json')).and_return(cwd_kafka)

        Kafkat::Config.load!
        expect(Kafkat::Config.kafka_path).to eq('/opt/kafka-3')
        expect(Kafkat::Config.zk_path).to eq('localhost:2183')
        expect(Kafkat::Config.log_path).to eq('/kafka-3')
      end

      it 'loads .kafkat.json on fallthrough' do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(File.expand_path('.kafkat.json')).and_return(true)
        # Mixlib::Config uses IO.read
        allow(IO).to receive(:read).and_return(nil)
        allow(IO).to receive(:read).with(File.expand_path('.kafkat.json')).and_return(cwd_kafka)

        Kafkat::Config.load!
        expect(Kafkat::Config.kafka_path).to eq('/opt/kafka-3')
        expect(Kafkat::Config.zk_path).to eq('localhost:2183')
        expect(Kafkat::Config.log_path).to eq('/kafka-3')
      end

      it 'loads a custom config file' do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(File.expand_path('.custom.json')).and_return(true)
        allow(IO).to receive(:read).and_return(nil)
        allow(IO).to receive(:read).with(File.expand_path('.custom.json')).and_return(custom_kafka)

        Kafkat::Config.load!(paths: ['.custom.json'])
        expect(Kafkat::Config.kafka_path).to eq('/opt/kafka-4')
        expect(Kafkat::Config.zk_path).to eq('localhost:2184')
        expect(Kafkat::Config.log_path).to eq('/kafka-4')
      end
    end
  end
end
