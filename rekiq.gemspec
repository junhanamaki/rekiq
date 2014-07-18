# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rekiq/version'

Gem::Specification.new do |spec|
  spec.name          = "rekiq"
  spec.version       = Rekiq::VERSION
  spec.authors       = ["junhanamaki"]
  spec.email         = ["jun.hanamaki@gmail.com"]
  spec.summary       = %q{recurring worker extension for sidekiq}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rspec", '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.7'
  spec.add_development_dependency 'factory_girl', '~> 4.4'
  spec.add_development_dependency 'jazz_hands', '~> 0.5'
  spec.add_development_dependency 'ice_cube', '~> 0.12'

  spec.add_runtime_dependency 'activemodel'
  spec.add_runtime_dependency 'sidekiq', '~> 3.2'
end