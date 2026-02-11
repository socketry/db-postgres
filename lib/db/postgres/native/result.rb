# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require_relative "../native"

module DB
	module Postgres
		module Native
			ffi_define_enumeration :query_status, [
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
			
			ffi_attach_function :PQresultStatus, [:pointer], :query_status, as: :result_status
			ffi_attach_function :PQresultErrorMessage, [:pointer], :string, as: :result_error_message
			
			ffi_attach_function :PQntuples, [:pointer], :int, as: :row_count
			ffi_attach_function :PQnfields, [:pointer], :int, as: :field_count
			ffi_attach_function :PQfname, [:pointer, :int], :string, as: :field_name
			ffi_attach_function :PQftype, [:pointer, :int], :int, as: :field_type
			
			ffi_attach_function :PQgetvalue, [:pointer, :int, :int], :string, as: :get_value
			ffi_attach_function :PQgetisnull, [:pointer, :int, :int], :int, as: :get_is_null
			
			ffi_attach_function :PQclear, [:pointer], :void, as: :clear
			
			ffi_attach_function :PQputCopyEnd, [:pointer, :string], :int, as: :put_copy_end
			ffi_attach_function :PQgetCopyData, [:pointer, :pointer, :int], :int, as: :get_copy_data
			ffi_attach_function :PQfreemem, [:pointer], :void, as: :free_memory
			
			# A result set from a database query with row iteration and type casting.
			class Result < FFI::Pointer
				# Initialize a new result set wrapper.
				# @parameter connection [Connection] The connection that produced this result.
				# @parameter types [Hash] Type mapping for field conversion.
				# @parameter address [FFI::Pointer] The pointer to the native result.
				def initialize(connection, types = {}, address)
					super(address)
					
					@connection = connection
					@fields = nil
					@types = types
					@casts = nil
				end
				
				# Get the number of fields in this result set.
				# @returns [Integer] The field count.
				def field_count
					Native.field_count(self)
				end
				
				# Get the type converters for each field.
				# @returns [Array] The array of type converter objects.
				def field_types
					field_count.times.collect{|i| @types[Native.field_type(self, i)]}
				end
				
				# Get the field names for this result set.
				# @returns [Array(String)] The array of field names.
				def field_names
					field_count.times.collect{|i| Native.field_name(self, i)}
				end
				
				# Get the number of rows in this result set.
				# @returns [Integer] The row count.
				def row_count
					Native.row_count(self)
				end
				
				# Cast row values to appropriate Ruby types.
				# @parameter row [Array] The raw row data.
				# @returns [Array] The row with values cast to proper types.
				def cast!(row)
					@casts ||= self.field_types
					
					row.size.times do |index|
						if cast = @casts[index]
							row[index] = cast.parse(row[index])
						end
					end
					
					return row
				end
				
				# Iterate over each row in the result set.
				# @yields {|row| ...} Each row as an array.
				# 	@parameter row [Array] The current row data.
				def each
					row_count.times do |i|
						yield cast!(get_row(i))
					end
					
					Native.clear(self)
				end
				
				# Map over each row in the result set.
				# @yields {|row| ...} Each row as an array.
				# 	@parameter row [Array] The current row data.
				# @returns [Array] The mapped results.
				def map(&block)
					results = []
					
					self.each do |row|
						results << yield(row)
					end
					
					return results
				end
				
				# Convert the entire result set to an array.
				# @returns [Array(Array)] All rows as arrays.
				def to_a
					rows = []
					
					self.each do |row|
						rows << row
					end
					
					return rows
				end
				
			protected
				
				def get_value(row, field)
					if Native.get_is_null(self, row, field) == 0
						Native.get_value(self, row, field)
					end
				end
				
				def get_row(row)
					field_count.times.collect{|j| get_value(row, j)}
				end
			end
		end
	end
end
