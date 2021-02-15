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

require_relative 'result'
require_relative 'field'
require_relative '../error'

module DB
	module Postgres
		module Native
			class Strings
				def initialize(values)
					@array = FFI::MemoryPointer.new(:pointer, values.size + 1)
					@pointers = values.map do |value|
						FFI::MemoryPointer.from_string(value.to_s)
					end
					@array.write_array_of_pointer(@pointers)
				end
				
				attr :array
			end
			
			attach_function :connect_start_params, :PQconnectStartParams, [:pointer, :pointer, :int], :pointer
			
			enum :polling_status, [
				:failed,
				:wait_readable,
				:wait_writable,
				:ok,
			]
			
			attach_function :connect_poll, :PQconnectPoll, [:pointer], :polling_status
			
			# Close the connection and release underlying resources.
			attach_function :finish, :PQfinish, [:pointer], :void
			
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
			
			# Submits a command to the server without waiting for the result(s). 1 is returned if the command was successfully dispatched and 0 if not (in which case, use PQerrorMessage to get more information about the failure).
			attach_function :send_query, :PQsendQuery, [:pointer, :string], :int
			
			# int PQsendQueryParams(PGconn *conn, const char *command, int nParams, const Oid *paramTypes, const char * const *paramValues, const int *paramLengths, const int *paramFormats, int resultFormat);
			attach_function :send_query_params, :PQsendQueryParams, [:pointer, :string, :int, :pointer, :pointer, :pointer, :pointer, :int], :int
			
			attach_function :set_single_row_mode, :PQsetSingleRowMode, [:pointer], :int
			
			attach_function :get_result, :PQgetResult, [:pointer], :pointer
			
			# If input is available from the server, consume it:
			attach_function :consume_input, :PQconsumeInput, [:pointer], :int
			
			# Returns 1 if a command is busy, that is, PQgetResult would block waiting for input. A 0 return indicates that PQgetResult can be called with assurance of not blocking.
			attach_function :is_busy, :PQisBusy, [:pointer], :int
			
			attach_function :escape_literal, :PQescapeLiteral, [:pointer, :string, :size_t], :pointer
			attach_function :escape_identifier, :PQescapeIdentifier, [:pointer, :string, :size_t], :pointer
			
			module IO
				def self.new(fd, mode)
					Async::IO::Generic.new(::IO.new(fd, mode, autoclose: false))
				end
			end
			
			class Connection < FFI::Pointer
				def self.connect(wrapper: IO, types: DEFAULT_TYPES, **options)
					# Postgres expects "dbname" as the key name:
					if database = options.delete(:database)
						options[:dbname] = database
					end
					
					# Postgres expects "user" as the key name:
					if username = options.delete(:username)
						options[:user] = username
					end
					
					keys = Strings.new(options.keys)
					values = Strings.new(options.values)
					
					pointer = Native.connect_start_params(keys.array, values.array, 0)
					Native.set_nonblocking(pointer, 1)
					
					io = wrapper.new(Native.socket(pointer), "r+")
					
					while status = Native.connect_poll(pointer)
						break if status == :ok || status == :failed
						
						# one of :wait_readable or :wait_writable
						io.send(status)
					end
					
					if status == :failed
						io.close
						
						error_message = Native.error_message(pointer)
						
						Native.finish(pointer)
						
						raise Error, "Could not connect: #{error_message}"
					end
					
					return self.new(pointer, io, types)
				end
				
				def initialize(address, io, types)
					super(address)
					
					@io = io
					@types = types
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
				
				def escape_literal(value)
					value = value.to_s
					
					result = Native.escape_literal(self, value, value.bytesize)
					
					string = result.read_string
					
					Native.free_memory(result)
					
					return string
				end
				
				def escape_identifier(value)
					value = value.to_s
					
					result = Native.escape_identifier(self, value, value.bytesize)
					
					string = result.read_string
					
					Native.free_memory(result)
					
					return string
				end
				
				def single_row_mode!
					Native.set_single_row_mode(self)
				end
				
				def send_query(statement)
					check! Native.send_query(self, statement)
					
					flush
				end
				
				def next_result(types: @types)
					if result = self.get_result
						status = Native.result_status(result)
						
						if status == :fatal_error
							message = Native.result_error_message(result)
							
							Native.clear(result)
							
							raise Error, "Could not get next result: #{message}"
						end
						
						return Result.new(self, types, result)
					end
				end
				
				# Silently discard any results that application didn't read.
				def discard_results
					while result = self.get_result
						status = Native.result_status(result)
						Native.clear(result)
						
						case status
						when :copy_in
							self.put_copy_end("Discard results")
						when :copy_out
							self.flush_copy_out
						end
					end
					
					return nil
				end
				
				protected
				
				def get_result
					while true
						check! Native.consume_input(self)
						
						while Native.is_busy(self) == 0
							result = Native.get_result(self)
							
							# Did we finish reading all results?
							if result.null?
								return nil
							else
								return result
							end
						end
						
						@io.wait_readable
					end
				end
				
				def put_copy_end(message = nil)
					while true
						status = Native.put_copy_end(self, message)
						
						if status == -1
							message = Native.error_message(self)
							raise Error, message
						elsif status == 0
							@io.wait_writable
						else
							break
						end
					end
				end
				
				def flush_copy_out
					buffer = FFI::MemoryPointer.new(:pointer, 1)
					
					while true
						status = Native.get_copy_data(self, buffer, 1)
						
						if status == -2
							message = Native.error_message(self)
							raise Error, message
						elsif status == -1
							break
						elsif status == 0
							@io.wait_readable
						else
							Native.free_memory(buffer.read_pointer)
						end
					end
				end
				
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
				
				def check!(result)
					if result == 0
						message = Native.error_message(self)
						raise Error, message
					end
				end
			end
		end
	end
end
