# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "covered/sus"
include Covered::Sus

::CREDENTIALS = {
	username: "test",
	password: "test",
	database: "test",
	host: "127.0.0.1"
}

::CREDENTIALS_URL = {
	dbname: 'postgresql://test:test@127.0.0.1/test'
}
