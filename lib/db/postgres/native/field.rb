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

require_relative 'types'

module DB
	module Postgres
		module Native
			DEFAULT_TYPES = {
				# Pseudo types:
				primary_key: Types::Integer.new('BIGSERIAL PRIMARY KEY'),
				foreign_key: Types::Integer.new('BIGINT'),
				text: Types::Text.new("TEXT"),
				string: Types::Text.new("VARCHAR(255)"),
				
				# Symbolic types:
				decimal: Types::Decimal.new,
				boolean: Types::Boolean.new,
				
				smallint: Types::Integer.new("SMALLINT"),
				integer: Types::Integer.new("INTEGER"),
				bigint: Types::Integer.new("BIGINT"),
				
				float: Types::Float.new,
				double: Types::Float.new("DOUBLE"),
				
				timestamp: Types::DateTime.new("TIMESTAMP"),
				date: Types::Date.new,
				datetime: Types::DateTime.new("DATETIME"),
				year: Types::Integer.new("LONG"),
				
				json: Types::JSON.new,
				enum: Types::Symbol.new,
				
				# Native types:
				# This data is extracted by hand from:
				# <https://github.com/postgres/postgres/blob/master/src/include/catalog/pg_type.dat>.
				# These are hard coded OIDs.
				16 => Types::Boolean.new,
				
				20 => Types::Integer.new("int8"),
				21 => Types::Integer.new("int2"),
				23 => Types::Integer.new("int4"),
				
				114 => Types::JSON.new,
				
				700 => Types::Float.new('float4'),
				701 => Types::Float.new('float8'),
				
				1082 => Types::Date.new,
				1083 => Types::DateTime.new("TIME"),
				
				1114 => Types::DateTime.new("TIMESTAMP"),
				1184 => Types::DateTime.new("TIMESTAMPTZ"),
				
				1700 => Types::Decimal.new,
				
				# Not sure if this is ever used?
				3500 => Types::Symbol.new,
			}
		end
	end
end
