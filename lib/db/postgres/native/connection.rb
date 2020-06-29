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

require_relative 'query'
require_relative 'result'

module DB
	module Postgres
		module Native
			# Synchronous connection.
			attach_function :connect, :PQconnectdb, [:string], :pointer
			attach_function :finish, :PQfinish, [:pointer], :void
			
			# Asyncronous connection.
			attach_function :connect_start, :PQconnectStart, [:string], :pointer
			
			enum :polling_status, [
				:failed,
				:wait_readable,
				:wait_writable,
				:ok,
			]
			
			attach_function :connect_poll, :PQconnectPoll, [:pointer], :polling_status
			
			attach_function :error_message, :PQerrorMessage, [:pointer], :string
			
			enum :status, [
				# Normal mode:
				:ok,
				:bad,
				
				# Non-blocking mode:
				:started, # Waiting for connection to be made.
				:made, # Connection OK; waiting to send.
				:awaiting_response, #Waiting for a response from the postmaster.
				:auth_ok, # Received authentication; waiting for backend startup.
				:setenv, # Negotiating environment.
				:ssl_startup, # Negotiating SSL.
				:needed, # Internal state: connect() needed
				:check_writable, # Check if we could make a writable connection.
				:consume, # Wait for any pending message and consume them.
			]
			
			attach_function :status, :PQstatus, [:pointer], :status
			
			attach_function :socket, :PQsocket, [:pointer], :int
			
			attach_function :set_nonblocking, :PQsetnonblocking, [:pointer, :int], :int
			attach_function :flush, :PQflush, [:pointer], :int
			
			class Connection < FFI::Pointer
				def initialize(address, io)
					super(address)
					
					@io = io
				end
				
				def self.connect(connection_string = "", io: ::IO)
					pointer = Native.connect_start(connection_string)
					
					io = io.new(Native.socket(pointer), "r+")
					
					while status = Native.connect_poll(pointer)
						break if status == :ok || status == :failed
						
						# one of :wait_readable or :wait_writable
						io.send(status)
					end
					
					Native.set_nonblocking(pointer, 1)
					
					return self.new(pointer, io)
				end
				
				# Return the status of the connection.
				def status
					Native.status(self)
				end
				
				# Return the last error message.
				def error_message
					Native.error_message(self)
				end
				
				# Return the underlying socket used for IO.
				def socket
					Native.socket(self)
				end
				
				# Close the connection.
				def close
					Native.finish(self)
					
					@io.close
				end
				
				def single_row_mode!
					Native.set_single_row_mode(self)
				end
				
				def send_query(statement)
					check! Native.send_query(self, statement)
					
					self.flush
				end
				
				def next_result
					while true
						check! Native.consume_input(self)
						
						while Native.is_busy(self) == 0
							result = Native.get_result(self)
							
							# Did we finish reading all results?
							if result.null?
								return nil
							else
								return Result.new(result)
							end
						end
						
						@io.wait_readable
					end
				end
				
				private
				
				# After sending any command or data on a nonblocking connection, call PQflush. If it returns 1, wait for the socket to become read- or write-ready. If it becomes write-ready, call PQflush again. If it becomes read-ready, call PQconsumeInput, then call PQflush again. Repeat until PQflush returns 0. (It is necessary to check for read-ready and drain the input with PQconsumeInput, because the server can block trying to send us data, e.g. NOTICE messages, and won't read our data until we read its.) Once PQflush returns 0, wait for the socket to be read-ready and then read the response as described above.
				def flush
					while true
						case Native.flush(self)
						when 1
							@io.wait_any
							
							check! Native.consume_input(self)
						when 0
							return
						end
					end
				end
				
				def check! result
					if result == 0
						message = Native.error_message(self)
						raise Error.new(message)
					end
				end
			end
		end
	end
end
