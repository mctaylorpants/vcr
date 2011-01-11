require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'

# Ruby 1.9.1 has a different yaml serialization format.
YAML_SERIALIZATION_VERSION = RUBY_VERSION == '1.9.1' ? '1.9.1' : 'not_1.9.1'

Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'vcr'
require 'monkey_patches'

module VCR
  SPEC_ROOT = File.dirname(__FILE__)
end

RSpec.configure do |config|
  config.extend TempCassetteLibraryDir
  config.extend DisableWarnings
  config.extend MonkeyPatches::RSpecMacros
  config.extend WebMockMacros

  config.color_enabled = true
  config.debug = RUBY_INTERPRETER == :mri && RUBY_VERSION != '1.9.2'

  config.before(:each) do
    VCR.turn_on! unless VCR.turned_on?
    VCR.eject_cassette while VCR.current_cassette

    VCR::Config.default_cassette_options = { :record => :new_episodes }
    VCR::Config.stub_with :fakeweb
    VCR::Config.clear_hooks

    WebMock.allow_net_connect!
    WebMock.reset!

    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry

    VCR::HttpStubbingAdapters::Faraday.reset!
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.alias_it_should_behave_like_to :it_performs, 'it performs'
end

http_stubbing_dir = File.join(File.dirname(__FILE__), '..', 'lib', 'vcr', 'http_stubbing_adapters')
Dir[File.join(http_stubbing_dir, '*.rb')].each do |file|
  next if RUBY_INTERPRETER != :mri && file =~ /(typhoeus)/
  require "vcr/http_stubbing_adapters/#{File.basename(file)}"
end
