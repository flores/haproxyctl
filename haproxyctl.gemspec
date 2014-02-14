# -*- encoding: utf-8 -*-
require File.expand_path('../lib/haproxyctl/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Carlo Flores"]
  gem.email         = ["github@petalphile.com"]
  gem.description   = %q{This is a simple wrapper to make life with HAProxy a little more convenient. Acts as an init script for start, stop, reload, restart, etc. Leverages 'socket' to enable and disable servers on the fly. Formats server weight and backends in a readable way. Provides Nagios and Cloudkick health checks. Compatible with RHEL chkconfig/service.}
  gem.summary       = %q{Wrapper to talk to the HAProxy socket, as well as regular init (start|stop|status|etc)}
  gem.homepage      = "https://github.com/flores/haproxyctl"
  gem.rubyforge_project = "haproxyctl"
  gem.license       = "MIT"
  gem.files         = `git ls-files`.split($\)
  gem.files.reject! { |fn| fn.include? "rhapr" }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "haproxyctl"
  gem.require_paths = ["lib"]
  gem.version       = HAProxyCTL::VERSION
end
