# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'db/postgres/connection'
require 'sus/fixtures/async'

ATimestamp = Sus::Shared("a timestamp") do |zone, time, expected|
	it "can get timestamps with microseconds and timezone" do
		connection.send_query("SET TIME ZONE '#{zone}'")
		
		buffer = String.new
		buffer << "SELECT "
		connection.append_literal(time, buffer)
		buffer << "::TIMESTAMPTZ"
		
		connection.send_query buffer
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be == expected
	ensure
		connection.close
	end
end

describe DB::Postgres::Connection do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:connection) {subject.new(**CREDENTIALS)}
		
	# PG produces: "2022-11-11 12:38:59.123456+00"
	it_behaves_like ATimestamp, 'UTC', '2022-11-11 23:38:59.123456+11', Time.new(2022, 11, 11, 23, 38, BigDecimal('59.123456'), '+11:00')
	
	# PG produces: "2022-11-11 12:38:59+00"
	it_behaves_like ATimestamp, 'UTC', '2022-11-11 23:38:59+11', Time.new(2022, 11, 11, 23, 38, BigDecimal('59'), '+11:00')
	
	# PG produces: "2022-11-11 23:38:59.123456+00"
	it_behaves_like ATimestamp, 'UTC', '2022-11-11 23:38:59.123456', Time.new(2022, 11, 11, 23, 38, BigDecimal('59.123456'), '+00:00')
	
	# PG produces: "2022-11-11 23:38:59+11"
	it_behaves_like ATimestamp, 'Australia/Sydney', '2022-11-11 23:38:59', Time.new(2022, 11, 11, 23, 38, BigDecimal('59'), '+11:00')
	
	# PG produces: "2022-11-12 06:08:59.123456+11"
	it_behaves_like ATimestamp, 'Australia/Sydney', '2022-11-11 23:38:59.123456+04:30', Time.new(2022, 11, 11, 23, 38, BigDecimal('59.123456'), '+04:30')
	
	# PG produces: "2000-01-01 05:30:00+05:30"
	it_behaves_like ATimestamp, 'Asia/Kolkata', '2000-01-01 00:00:00+00', Time.new(2000, 1, 1, 5, 30, 0, '+05:30')
	
	# PG produces: "2022-11-11 23:38:59+01"
	it_behaves_like ATimestamp, 'Europe/Lisbon', '2022-11-11 23:38:59+01', Time.new(2022, 11, 11, 23, 38, BigDecimal('59'), '+01:00')
	
	# PG produces: "infinity"
	it_behaves_like ATimestamp, 'UTC', 'infinity', 'infinity'
	
	# PG produces: "-infinity"
	it_behaves_like ATimestamp, 'UTC', '-infinity', '-infinity'
	
	# PG produces: null
	it_behaves_like ATimestamp, 'UTC', nil, nil
end
