
RSpec.describe FFI::Postgres::Lib do
	it "should connect to local postgres" do
		connection = FFI::Postgres::Lib.connect("host=localhost")
		
		status = FFI::Postgres::Lib.status(connection)
		
		expect(status).to be == :ok
		
		FFI::Postgres::Lib.finish(connection)
	end
end