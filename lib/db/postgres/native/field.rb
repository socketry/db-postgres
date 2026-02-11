# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "types"

module DB
	module Postgres
		module Native
			DEFAULT_TYPES = {
				# Pseudo types:
				primary_key: Types::Integer.new("BIGSERIAL PRIMARY KEY"),
				foreign_key: Types::Integer.new("BIGINT"),
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
				
				timestamp: Types::DateTime.new("TIMESTAMPTZ"),
				date: Types::Date.new,
				datetime: Types::DateTime.new("TIMESTAMPTZ"),
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
				
				700 => Types::Float.new("float4"),
				701 => Types::Float.new("float8"),
				
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
