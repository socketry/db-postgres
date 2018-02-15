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

require_relative 'lib/connection'
require_relative 'lib/query'

require 'io/wait'

module FFI
	module Postgres
		class Connection < Pointer
			def initialize(address, io)
				super(address)
				
				@io = io
			end
			
			def self.connect(connection_string = "", io: ::IO)
				pointer = Lib.connect_start(connection_string)
				
				io = io.new(Lib.socket(pointer), "r+")
				
				while status = Lib.connect_poll(pointer)
					break if status == :ok || status == :failed
					
					# one of :wait_readable or :wait_writable
					io.send(status)
				end
				
				return self.new(pointer, io)
			end
			
			# Return the status of the connection.
			def status
				Lib.status(self)
			end
			
			# Return the last error message.
			def error_message
				Lib.error_message(self)
			end
			
			# Return the underlying socket used for IO.
			def socket
				Lib.socket(self)
			end
			
			# Close the connection.
			def close
				Lib.finish(self)
			end
			
			def query(string)
				check! Lib.send_query(self, string)
				
				while true
					@io.wait_readable
					
					check! Lib.consume_input(self)
					
					while Lib.is_busy(self) == 0
						result = Lib.get_result(self)
						yield result
					end
				end
			end
				
			private
			
			def check! result
				if result == 0
					message = Lib.error_message(self)
					raise Error.new(message)
				end
			end
		end
	end
end
