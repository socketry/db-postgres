# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/pool/resource'
require 'async/io/generic'

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
				@native.close
				
				super
			end
			
			def append_string(value, buffer = String.new)
				buffer << @native.escape_literal(value)
				
				return buffer
			end
			
			def append_literal(value, buffer = String.new)
				case value
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
				
				buffer << " BIGSERIAL"
				
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
			
			def next_result
				@native.next_result
			end
		end
	end
end
