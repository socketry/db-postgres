# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'db/postgres/connection'
require 'sus/fixtures/async'

describe DB::Postgres::Connection do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:connection) {subject.new(**CREDENTIALS)}
	
	it "should connect to local postgres" do
		expect(connection.status).to be == :ok
	ensure
		connection.close
	end
	
	it "should execute query" do
		connection.send_query("SELECT 42 AS LIFE")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42]]
	ensure
		connection.close
	end

	it "should execute query with arguments" do
		connection.send_query_params("SELECT $1::BIGINT AS LIFE, $2 AS ANSWER", 42, "Life, the universe and everything")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42, "Life, the universe and everything"]]
	ensure
		connection.close
	end
	
	it "should execute multiple queries" do
		connection.send_query("SELECT 42 AS LIFE; SELECT 24 AS LIFE")
		
		result = connection.next_result
		expect(result.to_a).to be == [[42]]
		
		result = connection.next_result
		expect(result.to_a).to be == [[24]]
	ensure
		connection.close
	end
	
	it "can get current time" do
		connection.send_query("SELECT (NOW() AT TIME ZONE 'UTC') AS NOW")
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be_within(1).of(Time.now.utc)
	ensure
		connection.close
	end
	
	it "can handle bytea output" do
		connection.send_query("SELECT '\\x414243003839'::BYTEA")
		
		result = connection.next_result
		cell = result.to_a.first.first
		expect(cell).to be == "ABC\x0089".b
		expect(cell.encoding).to be == Encoding::ASCII_8BIT
	ensure
		connection.close
	end
	
	with '#append_string' do
		it "should escape string" do
			expect(connection.append_string("Hello 'World'")).to be == "'Hello ''World'''"
			expect(connection.append_string('Hello "World"')).to be == "'Hello \"World\"'"
		ensure
			connection.close
		end
	end
	
	with '#append_literal' do
		it "should escape string" do
			expect(connection.append_literal("Hello World")).to be == "'Hello World'"
		ensure
			connection.close
		end
		
		it "should not escape integers" do
			expect(connection.append_literal(42)).to be == "42"
		ensure
			connection.close
		end
	end
	
	with '#append_identifier' do
		it "should escape identifier" do
			expect(connection.append_identifier("Hello World")).to be == '"Hello World"'
		ensure
			connection.close
		end
		
		it "can handle booleans" do
			buffer = String.new
			buffer << "SELECT "
			connection.append_literal(true, buffer)
			
			connection.send_query(buffer)
			
			result = connection.next_result
			row = result.to_a.first
			
			expect(row.first).to be == true
		ensure
			connection.close
		end
	end
end
