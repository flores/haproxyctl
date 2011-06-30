# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rhapr/version'

Gem::Specification.new do |s|
  s.name        = 'rhapr'
  s.version     = Rhapr::VERSION
  s.authors     = ['Scott Gonyea']
  s.email       = ['me@sgonyea.com']
  s.homepage    = 'https://github.com/sgonyea/rhapr'
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.add_dependency 'yard', '~>0.6'

  s.add_development_dependency 'rspec', '~>2.4'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
