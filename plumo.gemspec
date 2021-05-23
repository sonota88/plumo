lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plumo/version'

Gem::Specification.new do |spec|
  spec.name          = "plumo"
  spec.version       = Plumo::VERSION
  spec.authors       = ["sonota88"]
  spec.email         = ["yosiot8753@gmail.com"]

  spec.summary       = %q{Easy 2d-graphincs using Ruby and Canvas}
  spec.description   = %q{Easy 2d-graphincs using Ruby and Canvas}
  spec.homepage      = "https://github.com/sonota88/plumo"
  spec.license       = 'BSD 2-Clause "Simplified"'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|examples)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.0"
  # spec.add_development_dependency "minitest", "~> 5.0"
end
