# frozen_string_literal: true

require_relative "lib/db/postgres/version"

Gem::Specification.new do |spec|
	spec.name = "db-postgres"
	spec.version = DB::Postgres::VERSION
	
	spec.summary = "Ruby FFI bindings for libpq C interface."
	spec.authors = ["Samuel Williams", "Aidan Samuel", "Tony Schneider"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/db-postgres"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/db-postgres/",
		"funding_uri" => "https://github.com/sponsors/ioquatix",
		"source_code_uri" => "https://github.com/socketry/db-postgres.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "async-pool"
	spec.add_dependency "ffi-native", "~> 0.4"
end
