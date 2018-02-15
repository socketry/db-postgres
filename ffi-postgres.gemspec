
require_relative 'lib/ffi/postgres/version'

Gem::Specification.new do |spec|
	spec.name          = "ffi-postgres"
	spec.version       = FFI::Postgres::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.description   = %q{Ruby FFI bindings for libpq C interface.}
	spec.summary       = %q{Ruby FFI bindings for libpq C interface.}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_dependency "ffi"

	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
