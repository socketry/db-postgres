
require 'ffi/postgres/connection'

RSpec.describe FFI::Postgres::Lib do
	let(:connection_string) {"host=localhost dbname=test"}
	let(:connection) {FFI::Postgres::Connection.connect(connection_string)}
	
	it "should connect to local postgres" do
		expect(connection.status).to be == :ok
		
		connection.close
	end
	
	it "should execute query" do
		connection.query("SELECT 42 AS LIFE") do |results|
			puts results.inspect
		end
	end
end
