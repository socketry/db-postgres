# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "ffi/native"
require "ffi/native/config_tool"

module DB
	module Postgres
		# Provides FFI bindings to the native PostgreSQL client library (libpq).
		module Native
			extend FFI::Native::Library
			extend FFI::Native::Loader
			extend FFI::Native::ConfigTool
			
			ffi_load("pq") ||
				ffi_load_using_config_tool(%w{pg_config --libdir}, names: ["pq"]) ||
				ffi_load_failure(<<~EOF)
					Unable to load libpq!
					
					## Ubuntu
					
						sudo apt-get install libpq-dev
					
					## Arch Linux
					
						sudo pacman -S postgresql
					
					## MacPorts
					
						sudo port install postgresql11
					
					## Homebrew
					
						brew install postgresql
					
				EOF
		end
	end
end
