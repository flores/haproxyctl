require 'bundler/setup'

Bundler.require :default
Bundler.require :development

Dir[ Bundler.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |c|
  c.include CustomMatchers
  c.include ConfigFixtures
end
