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

require_relative '../lib'

module FFI
	module Postgres
		module Lib
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
		end
	end
end
