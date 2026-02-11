# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require_relative "connection"

module DB
	module Postgres
		# A database adapter for connecting to PostgreSQL servers.
		class Adapter
			# Initialize a new adapter with connection options.
			# @parameter options [Hash] Connection options to be passed to the connection.
			def initialize(**options)
				@options = options
			end
			
			# @attribute [Hash] The connection options.
			attr :options
			
			# Create a new database connection.
			# @returns [Connection] A new connection instance.
			def call
				Connection.new(**@options)
			end
		end
	end
end
