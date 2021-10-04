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
						if string
							parts = string.split(/[\-\s:]/)
							
							return Time.utc(*parts)
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
