
require 'ffi/postgres/connection'

RSpec.describe FFI::Postgres::Lib do
	let(:connection_string) {"host=localhost dbname=test"}
	
	it "should connect to local postgres" do
		connection = FFI::Postgres::Connection.connect(connection_string)
		
		expect(connection.status).to be == :ok
		
		connection.close
	end
end
