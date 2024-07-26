# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require 'json'
require 'bigdecimal'

module DB
	module Postgres
		module Native
			module Types
				class Text
					def initialize(name = "TEXT")
						@name = name
					end
					
					attr :name
					
					def parse(string)
						string
					end
				end
				
				class Integer
					def initialize(name = "INTEGER")
						@name = name
					end
					
					attr :name
					
					def parse(string)
						Integer(string) if string
					end
				end
				
				class Boolean
					def name
						"BOOLEAN"
					end
					
					def parse(string)
						string == 't'
					end
				end
				
				class Decimal
					def name
						"DECIMAL"
					end
					
					def parse(string)
						BigDecimal(string) if string
					end
				end
				
				class Float
					def initialize(name = "FLOAT")
						@name = name
					end
					
					attr :name
					
					def parse(string)
						Float(string) if string
					end
				end
				
				class Symbol
					def name
						"ENUM"
					end
					
					def parse(string)
						string&.to_sym
					end
				end
				
				class DateTime
					def initialize(name = "TIMESTAMP")
						@name = name
					end
					
					attr :name
					
					def parse(string)
						if string == '-infinity' || string == 'infinity' || string.nil?
							return string
						end
						
						if match = string.match(/\A(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+(?:\.\d+)?)([-+]\d\d(?::\d\d)?)?\z/)
							parts = match.captures
							
							parts[5] = BigDecimal(parts[5])
							
							if parts[6].nil?
								parts[6] = '+00'
							end
							
							return Time.new(*parts)
						end
					end
				end
				
				class Date
					def name
						"DATE"
					end
					
					def parse(string)
						if string
							parts = string.split(/[\-\s:]/)
							
							return Time.utc(*parts)
						end
					end
				end
				
				class JSON
					def name
						"JSON"
					end
					
					def parse(string)
						::JSON.parse(string, symbolize_names: true) if string
					end
				end
			end
		end
	end
end
