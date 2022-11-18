# DB::Postgres

A light-weight wrapper for Ruby exposing [libpq](https://www.postgresql.org/docs/current/static/libpq.html).

[![Development Status](https://github.com/socketry/db-postgres/workflows/Development/badge.svg)](https://github.com/socketry/db-postgres/actions?workflow=Development)

## Installation

Add this line to your application's Gemfile:

    gem 'db-postgres'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db-postgres

## Usage


### A simple CREATE, INSERT and SELECT, with raw SQL

```ruby
require 'async'
require 'db/client'
require 'db/postgres'

Console.logger.level = :info

client = DB::Client.new(DB::Postgres::Adapter.new(
    database: 'test',
    host:     '172.17.0.3',
    password: 'test',
    username: 'postgres',
))

Async do
    session = client.session

    create = "CREATE TABLE IF NOT EXISTS my_table (a_timestamp TIMESTAMP NOT NULL)"
    session.query(create).call

    insert = "INSERT INTO my_table VALUES (NOW()), ('2022-12-12 12:13:14')"
    session.query(insert).call

    result = session.query("SELECT * FROM my_table WHERE a_timestamp > NOW()").call

    Console.logger.info result.field_types.to_s
    Console.logger.info result.field_names.to_s
    Console.logger.info result.to_a.to_s

ensure
    session&.close
end

=begin
 0.01s     info: [#<DB::Postgres::Native::Types::DateTime:0x00007eff3b13e688 @name="TIMESTAMP">]
 0.01s     info: ["a_timestamp"]
 0.01s     info: [[2022-12-12 12:13:14 UTC]]
=end
```

### Parameterized CREATE, INSERT and SELECT
The same process as before, but parameterized.
Always used the parameterized form when dealing with untrusted data.

```ruby
# ...

Async do
    session = client.session

    session.clause("CREATE TABLE IF NOT EXISTS")
        .identifier(:my_table)
        .clause("(")
            .identifier(:a_timestamp).clause("TIMESTAMP NOT NULL")
        .clause(")")
        .call

    session.clause("INSERT INTO")
        .identifier(:my_table)
        .clause("VALUES (")
            .literal("NOW()")
        .clause("), (")
            .literal("2022-12-12 12:13:14")
        .clause(")")
        .call

    result = session.clause("SELECT * FROM")
        .identifier(:my_table)
        .clause("WHERE")
        .identifier(:a_timestamp).clause(">").literal("NOW()")
        .call

    Console.logger.info result.field_types.to_s
    Console.logger.info result.field_names.to_s
    Console.logger.info result.to_a.to_s

ensure
    session&.close
end

=begin
 0.01s     info: [#<DB::Postgres::Native::Types::DateTime:0x00007eff3b13e688 @name="TIMESTAMP">]
 0.01s     info: ["a_timestamp"]
 0.01s     info: [[2022-12-12 12:13:14 UTC]]
=end
```

### A parameterized SELECT

```ruby
# ...

Async do |task|
    session = client.session
    result = session
        .clause("SELECT")
        .identifier(:column_one)
        .clause(",")
        .identifier(:column_two)
        .clause("FROM")
        .identifier(:another_table)
        .clause("WHERE")
        .identifier(:id)
        .clause("=")
        .literal(42)
        .call

    Console.logger.info "#{result.field_names}"
    Console.logger.info "#{result.to_a}"
end

=begin
 0.01s     info: ["column_one", "column_two"]
 0.01s     info: [["foo", "bar"], ["baz", "qux"]]
=end
```

### Concurrent queries
(Simulating slow queries with `PG_SLEEP`)

``` ruby
# ...

Async do |task|
    start = Time.now
    tasks = 10.times.map do
        task.async do
            session = client.session
            result = session.query("SELECT PG_SLEEP(10)").call
            result.to_a
        ensure
            session&.close
        end
    end

    results = tasks.map(&:wait)

    Console.logger.info "Elapsed time: #{Time.now - start}s"
end

=begin
10.05s     info: Elapsed time: 10.049756222s
=end

```

### Limited to 3 connections
(Simulating slow queries with `PG_SLEEP`)

``` ruby

# ...
require 'semaphore'

# ...

Async do
    semaphore = Async::Semaphore.new(3)
    tasks = 10.times.map do |i|
        semaphore.async do
            session = client.session
            Console.logger.info "Starting task #{i}"
            result = session.query("SELECT PG_SLEEP(10)").call
            result.to_a
        ensure
            session&.close
        end
    end

    results = tasks.map(&:wait)
    Console.logger.info "Done"
end

=begin
  0.0s     info: Starting task 0
  0.0s     info: Starting task 1
  0.0s     info: Starting task 2
10.02s     info: Completed task 0 after 10.017388464s
10.02s     info: Starting task 3
10.02s     info: Completed task 1 after 10.02111175s
10.02s     info: Starting task 4
10.03s     info: Completed task 2 after 10.027889587s
10.03s     info: Starting task 5
20.03s     info: Completed task 3 after 10.011089096s
20.03s     info: Starting task 6
20.03s     info: Completed task 4 after 10.008169111s
20.03s     info: Starting task 7
20.04s     info: Completed task 5 after 10.007644749s
20.04s     info: Starting task 8
30.04s     info: Completed task 6 after 10.011244562s
30.04s     info: Starting task 9
30.04s     info: Completed task 7 after 10.011565997s
30.04s     info: Completed task 8 after 10.004611464s
40.05s     info: Completed task 9 after 10.008239803s
40.05s     info: Done
=end
```

### Sequential vs concurrent inserts

``` ruby
# ...

DATA = 1_000_000.times.map { SecureRandom.hex }

def setup_tables(client)
    session = client.session

    create = "CREATE TABLE IF NOT EXISTS salts (salt CHAR(32))"
    session.query(create).call

    truncate = "TRUNCATE TABLE salts"
    session.query(truncate).call

    session.close
end

def chunked_insert(rows, client, task=Async::Task.current)
    task.async do
        session = client.session
        rows.each_slice(1000) do |slice|
            insert = "INSERT INTO salts VALUES " + slice.map { |x| "('#{x}')" }.join(",")
            session.query(insert).call
        end
    ensure
        session&.close
    end
end

Async do
    Console.logger.info "Setting up tables"
    setup_tables(client)
    Console.logger.info "Done"

    start = Time.now
    Console.logger.info "Starting sequential insert"
    chunked_insert(DATA, client).wait
    Console.logger.info "Completed sequential insert in #{Time.now - start}s"

    start = Time.now
    Console.logger.info "Starting concurrent insert"
    DATA.each_slice(10_000).map do |slice|
        chunked_insert(slice, client)
    end.each(&:wait)
    Console.logger.info "Completed concurrent insert in #{Time.now - start}s"
end

=begin
 1.45s     info: Setting up tables
 1.49s     info: Done
 1.49s     info: Starting sequential insert
 8.49s     info: Completed sequential insert in 7.006533933s
 8.49s     info: Starting concurrent insert
 9.92s     info: Completed concurrent insert in 1.431470847s
=end
```

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request

## License

Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
