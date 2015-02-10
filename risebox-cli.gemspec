lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rb/client/version'

Gem::Specification.new do |s|
  s.name = "risebox-cli"
  s.version = RB::Client::VERSION
  s.authors = ["Adrien THERY", "Nicolas NARDONE"]
  s.email = 'hello@risebox.co'
  s.summary = "Ruby client wrapper for Risebox HTTP API"
  s.homepage = "http://github.com/risebox/risebox-cli"
  s.license = ""

  s.add_runtime_dependency     'faraday',     '~> 0.8.8'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'

  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- spec/*`.split("\n")
  s.require_paths         = ["lib"]
  s.required_ruby_version = '>= 1.9.3'
end