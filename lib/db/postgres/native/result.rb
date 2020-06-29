# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../native'

module DB
	module Postgres
		module Native
			enum :exec_status, [
				:empty_query, # empty query string was executed
				:command_ok, # a query command that doesn't return anything was executed properly by the backend
				:tuples_ok, #  a query command that returns tuples was executed properly by the backend, PGresult contains the result tuples
				:copy_out, # Copy Out data transfer in progress
				:copy_in, # Copy In data transfer in progress
				:bad_response, # an unexpected response was recv'd from the backend
				:nonfatal_error, # notice or warning message
				:fatal_error, # query failed
				:copy_both, # Copy In/Out data transfer in progress
				:single_tuple, # single tuple from larger resultset
			]
			
			attach_function :result_status, :PQresultStatus, [:pointer], :exec_status
			
			attach_function :result_error_message, :PQresultErrorMessage, [:pointer], :string
			
			attach_function :row_count, :PQntuples, [:pointer], :int
			
			attach_function :field_count, :PQnfields, [:pointer], :int
			
			attach_function :field_name, :PQfname, [:pointer, :int], :string
			
			attach_function :get_value, :PQgetvalue, [:pointer, :int, :int], :string
			
			attach_function :clear, :PQclear, [:pointer], :void
			
			class Result < FFI::Pointer
				def field_count
					Native.field_count(self)
				end
				
				def field_names
					field_count.times.collect{|i| Native.field_name(self, i)}
				end
				
				def row_count
					Native.row_count(self)
				end
				
				def each
					row_count.times do |i|
						yield get_row(i)
					end
					
					Native.clear(self)
				end
				
				def to_a
					rows = []
					
					self.each do |row|
						rows << row
					end
					
					return rows
				end
				
			protected
				def get_value(row, field)
					Native.get_value(self, row, field)
				end
				
				def get_row(row)
					field_count.times.collect{|j| get_value(row, j)}
				end
			end
		end
	end
end
