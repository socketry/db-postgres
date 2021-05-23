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

require 'ffi/module'
require 'ffi/module/config_tool'

module DB
	module Postgres
		module Native
			extend FFI::Module::Library
			extend FFI::Module::Loader
			extend FFI::Module::ConfigTool
			
			ffi_load('pq') ||
				ffi_load_using_config_tool(%w{pg_config --libdir}, names: ['pq']) ||
				ffi_load_failure(<<~EOF)
					Unable to load libpq!
					
					## Ubuntu
					
						sudo apt-get install libpq-dev
					
					## Arch Linux
					
						sudo pacman -S postgresql
					
					## MacPorts
					
						sudo port install postgresql11
					
					## Homebrew
					
						brew install postgresql
					
				EOF
		end
	end
end
