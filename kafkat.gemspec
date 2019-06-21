$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'kafkat/version'

Gem::Specification.new do |s|
  s.name         = 'kafkat'
  s.version      = Kafkat::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ['Nelson Gauthier']
  s.email        = ['nelson@airbnb.com']
  s.homepage     = 'https://github.com/airbnb/kafkat'
  s.summary      = 'Simplified command-line administration for Kafka brokers'
  s.description  = s.summary
  s.license      = 'Apache-v2'

  s.files        = `git ls-files`.split($/)
  s.executables  = s.files.grep(%r{^bin/}) { |f| File.basename f }
  s.test_files   = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = 'lib'

  s.add_runtime_dependency 'colored', '~> 1.2'
  s.add_runtime_dependency 'highline', '~> 1.6', '>= 1.6.21'
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_runtime_dependency 'optimist', '~> 3.0'
  s.add_runtime_dependency 'mixlib-cli', '~> 1.7'
  s.add_runtime_dependency 'mixlib-config', '~> 3.0'
  s.add_runtime_dependency 'retryable', '~> 1.3', '>= 1.3.5'
  s.add_runtime_dependency 'zk', '~> 1.9', '>= 1.9.4'

  s.add_development_dependency 'activesupport', '>= 2', '< 5'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'factory_bot', '~> 5.0.0'
  s.add_development_dependency 'rake', '<= 10.5.0'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1.0'
  s.add_development_dependency 'rubocop', '~> 0.58.0'
  s.add_development_dependency 'rubocop-rspec', '~> 1.30.0'
  s.add_development_dependency 'simplecov', '~> 0.16.1'
  s.add_development_dependency 'pry', '~> 0.12'
  s.add_development_dependency 'rubocop-airbnb'
end
