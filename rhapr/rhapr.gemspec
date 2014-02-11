# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'rhapr/version'

Gem::Specification.new do |s|
  s.name        = 'rhapr'
  s.version     = Rhapr::VERSION
  s.authors     = ['Scott Gonyea']
  s.email       = ['me@sgonyea.com']
  s.homepage    = 'https://github.com/sgonyea/rhapr'
  s.summary     = %q{Rhapr wraps around HAProxy}
  s.description = %q{Rhapr is a ruby lib that wraps around HAProxy, enabling you to sanely decomission a process.}

  s.add_dependency 'yard', '~>0.6'

  s.add_development_dependency 'rspec', '~>2.4'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
