# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require_relative "connection"

module DB
	module Postgres
		class Adapter
			def initialize(**options)
				@options = options
			end
			
			attr :options
			
			def call
				Connection.new(**@options)
			end
		end
	end
end
