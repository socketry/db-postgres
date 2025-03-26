# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'async/pool/resource'
require_relative 'native/connection'

module DB
	module Postgres
		# This implements the interface between the underlying 
		class Connection < Async::Pool::Resource
			def initialize(**options)
				@native = Native::Connection.connect(**options)
				
				super()
			end
			
			def close
				if @native
					@native&.close
					@native = nil
				end
				
				super
			end
			
			def types
				@native.types
			end
			
			def append_string(value, buffer = String.new)
				buffer << @native.escape_literal(value)
				
				return buffer
			end
			
			def append_literal(value, buffer = String.new)
				case value
				when Time, DateTime, Date
					append_string(value.iso8601, buffer)
				when Numeric
					buffer << value.to_s
				when TrueClass
					buffer << 'TRUE'
				when FalseClass
					buffer << 'FALSE'
				when nil
					buffer << 'NULL'
				else
					append_string(value, buffer)
				end
				
				return buffer
			end
			
			def append_identifier(value, buffer = String.new)
				case value
				when Array
					first = true
					value.each do |part|
						buffer << '.' unless first
						first = false
						
						buffer << @native.escape_identifier(part)
					end
				else
					buffer << @native.escape_identifier(value)
				end
				
				return buffer
			end
			
			def key_column(name = 'id', primary: true, null: false)
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
			
			def status
				@native.status
			end
			
			def send_query(statement)
				@native.discard_results
				
				@native.send_query(statement)
			end
			
			def send_query_params(statement, *params)
				@native.discard_results
				
				@native.send_query_params(statement, *params)
			end
			
			def next_result
				@native.next_result
			end
		end
	end
end
