# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require_relative 'postgres/native'
require_relative 'postgres/connection'

require_relative 'postgres/adapter'

require 'db/adapters'
DB::Adapters.register(:postgres, DB::Postgres::Adapter)
