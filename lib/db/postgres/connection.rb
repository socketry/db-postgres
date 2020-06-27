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
require 'ffi/postgres'

module DB
	module Postgres
		module IO
			def self.new(fd, mode)
				Async::IO::Generic.new(::IO.new(fd, mode))
			end
		end
		
		# This implements the interface between the underlying 
		class Connection < Async::Pool::Resource
			def initialize(connection_string)
				@wrapper = FFI::Postgres::Connection.connect(
					connection_string, io: IO
				)
				
				super()
			end
			
			def send_query(statement)
				@wrapper.send_query(statement)
			end
			
			def next_result
				@wrapper.next_result
			end
			
			def call(statement, streaming: false)
				@wrapper.send_query(statement)
				
				@wrapper.single_row_mode! if streaming
				
				last_result = nil
				
				while result = @wrapper.next_result
					last_result = result
				end
				
				return last_result
			end
		end
	end
end
