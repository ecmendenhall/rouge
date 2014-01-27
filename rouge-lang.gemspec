# encoding: utf-8

require File.expand_path('../lib/rouge/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yuki Izumi"]
  gem.email         = ["rubygems@kivikakk.ee"]
  gem.description   = %q{Ruby + Clojure = Rouge.}
  gem.summary       = %q{An implementation of Clojure for Ruby.}
  gem.homepage      = "https://github.com/rouge-lang/rouge"

  gem.add_development_dependency('rake')
  gem.add_development_dependency('autotest')
  gem.add_development_dependency('autotest-growl')
  gem.add_development_dependency('autotest-fsevent')
  gem.add_development_dependency('ZenTest')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('term-ansicolor')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rouge-lang"
  gem.require_paths = ["lib"]
  gem.version       = Rouge::VERSION
end

# vim: set sw=2 et cc=80:
