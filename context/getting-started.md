# Getting Started

This guide explains how to get started with the `db-postgres` gem.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add db-postgres
~~~

## Usage

Here is an example of the basic usage of the adapter:

~~~ ruby
require 'async'
require 'db/postgres'

# Create an event loop:
Sync do
	# Create the adapter and connect to the database:
	adapter = DB::Postgres::Adapter.new(database: 'test')
	connection = adapter.call
	
	# Execute the query:
	result = connection.send_query("SELECT VERSION()")
	
	# Get the results:
	pp connection.next_result.to_a
	# => [["PostgreSQL 16.3 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 14.1.1 20240522, 64-bit"]]
ensure
	# Return the connection to the client connection pool:
	connection.close
end
~~~
