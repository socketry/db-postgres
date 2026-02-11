# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require "db/postgres/connection"
require "sus/fixtures/async"

describe DB::Postgres::Connection do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:connection) {subject.new(**CREDENTIALS_URL)}
	
	after do
		@connection&.close
	end
	
	it "should connect to local postgres" do
		expect(connection.status).to be == :ok
	end
	
	it "should execute query" do
		connection.send_query("SELECT 42 AS LIFE")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42]]
	end
	
	it "should execute multiple queries" do
		connection.send_query("SELECT 42 AS LIFE; SELECT 24 AS LIFE")
		
		result = connection.next_result
		expect(result.to_a).to be == [[42]]
		
		result = connection.next_result
		expect(result.to_a).to be == [[24]]
	end
	
	it "can get current time" do
		connection.send_query("SELECT (NOW() AT TIME ZONE "UTC") AS NOW")
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be_within(1).of(Time.now.utc)
	end
	
	with "#append_string" do
		it "should escape string" do
			expect(connection.append_string("Hello 'World'")).to be == "'Hello ''World'''"
			expect(connection.append_string('Hello "World"')).to be == "'Hello \"World\"'"
		end
	end
	
	with "#append_literal" do
		it "should escape string" do
			expect(connection.append_literal("Hello World")).to be == "'Hello World'"
		end
		
		it "should not escape integers" do
			expect(connection.append_literal(42)).to be == "42"
		end
	end
	
	with "#append_identifier" do
		it "should escape identifier" do
			expect(connection.append_identifier("Hello World")).to be == '"Hello World"'
		end
		
		it "can handle booleans" do
			buffer = String.new
			buffer << "SELECT "
			connection.append_literal(true, buffer)
			
			connection.send_query(buffer)
			
			result = connection.next_result
			row = result.to_a.first
			
			expect(row.first).to be == true
		end
	end
	
	with "#features" do
		it "should return configured PostgreSQL features" do
			features = connection.features
			
			expect(features.alter_column_type?).to be == true
			expect(features.using_clause?).to be == true
			expect(features.conditional_operations?).to be == true
			expect(features.transactional_schema?).to be == true
			expect(features.batch_alter_table?).to be == true
			expect(features.modify_column?).to be == false
		end
	end
end
