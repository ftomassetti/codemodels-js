# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'js-lightmodels/version'

Gem::Specification.new do |spec|
  spec.name          = "js-lightmodels"
  spec.version       = LightModels::Js::VERSION
  spec.authors       = ["Federico Tomassetti"]
  spec.email         = ["f.tomassetti@gmail.com"]
  spec.description   = %q{Generate Lightmodels from Javascript source files}
  spec.summary       = %q{Generate Lightmodels from Javascript source files}
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "lightmodels"
  spec.add_dependency "emf_jruby"
  spec.add_dependency "rkelly"    
  spec.add_dependency "rgen"      

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
