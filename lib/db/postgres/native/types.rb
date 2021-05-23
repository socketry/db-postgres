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

require 'ffi'

require 'json'
require 'bigdecimal'
require 'time'

module DB
	module Postgres
		module Native
			module Types
				module Boolean
					def self.parse(string)
						string == 't'
					end
				end
				
				module Integer
					def self.parse(string)
						Integer(string) if string
					end
				end
				
				module Decimal
					def self.parse(string)
						BigDecimal(string) if string
					end
				end
				
				module Float
					def self.parse(string)
						Float(string) if string
					end
				end
				
				module Symbol
					def self.parse(string)
						string&.to_sym
					end
				end
				
				module DateTime
					def self.parse(string)
						if string
							parts = string.split(/[\-\s:\.]/)
							
							return Time.utc(*parts)
						end
					end
				end
				
				module JSON
					def self.parse(string)
						::JSON.parse(string, symbolize_names: true) if string
					end
				end
			end
		end
	end
end
