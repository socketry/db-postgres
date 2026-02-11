# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "async/pool/resource"
require "db/features"
require_relative "native/connection"

module DB
	module Postgres
		# A high-level database connection that implements the standardized connection interface.
		# This class provides a bridge between the underlying native PostgreSQL interface and the DB gem's unified connection API.
		class Connection < Async::Pool::Resource
			# Initialize a new database connection.
			# @parameter options [Hash] Connection options passed to the native connection.
			def initialize(**options)
				@native = Native::Connection.connect(**options)
				
				super()
			end
			
			# Close the database connection and release resources.
			def close
				if @native
					@native&.close
					@native = nil
				end
				
				super
			end
			
			# Get the type mapping for database types.
			# @returns [Hash] The type mapping configuration.
			def types
				@native.types
			end
			
			# Append an escaped string value to the buffer.
			# @parameter value [String] The string value to escape and append.
			# @parameter buffer [String] The buffer to append to.
			# @returns [String] The buffer with the escaped string appended.
			def append_string(value, buffer = String.new)
				buffer << @native.escape_literal(value)
				
				return buffer
			end
			
			# Append a literal value to the buffer with appropriate formatting.
			# @parameter value [Object] The value to append (supports Time, Date, Numeric, Boolean, nil, and strings).
			# @parameter buffer [String] The buffer to append to.
			# @returns [String] The buffer with the formatted value appended.
			def append_literal(value, buffer = String.new)
				case value
				when Time, DateTime, Date
					append_string(value.iso8601, buffer)
				when Numeric
					buffer << value.to_s
				when TrueClass
					buffer << "TRUE"
				when FalseClass
					buffer << "FALSE"
				when nil
					buffer << "NULL"
				else
					append_string(value, buffer)
				end
				
				return buffer
			end
			
			# Append an escaped identifier to the buffer.
			# @parameter value [String | Array(String)] The identifier or array of identifiers to escape.
			# @parameter buffer [String] The buffer to append to.
			# @returns [String] The buffer with the escaped identifier appended.
			def append_identifier(value, buffer = String.new)
				case value
				when Array
					first = true
					value.each do |part|
						buffer << "." unless first
						first = false
						
						buffer << @native.escape_identifier(part)
					end
				else
					buffer << @native.escape_identifier(value)
				end
				
				return buffer
			end
			
			# Generate a key column definition for table creation.
			# @parameter name [String] The column name.
			# @parameter primary [Boolean] Whether this is a primary key column.
			# @parameter null [Boolean] Whether this column allows null values.
			# @returns [String] The column definition string.
			def key_column(name = "id", primary: true, null: false)
				buffer = String.new
				
				append_identifier(name, buffer)
				
				if primary
					buffer << " BIGSERIAL"
				else
					buffer << " BIGINT"
				end
				
				if primary
					buffer << " PRIMARY KEY"
				elsif !null
					buffer << " NOT NULL"
				end
				
				return buffer
			end
			
			# Get the current connection status.
			# @returns [Symbol] The status symbol from the server.
			def status
				@native.status
			end
			
			# Send a query to the database server.
			# @parameter statement [String] The SQL statement to execute.
			def send_query(statement)
				@native.discard_results
				
				@native.send_query(statement)
			end
			
			# Get the next result set from a multi-result query.
			# @returns [Native::Result | Nil] The next result set, or `nil` if no more results.
			def next_result
				@native.next_result
			end
			
			FEATURES = DB::Features.new(
				alter_column_type: true,
				using_clause: true,
				conditional_operations: true,
				transactional_schema: true,
				batch_alter_table: true,
				concurrent_schema: true,
				serial_columns: true,
			)
			
			# Database feature detection for migration and query building.
			# @returns [DB::Features] The supported database features.
			def features
				FEATURES
			end
		end
	end
end
