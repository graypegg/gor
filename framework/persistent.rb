# frozen_string_literal: true

class Persistent
  def self.inherited(klass)
    super
    @@classes ||= []
    @@classes.push klass
  end

  def initialize(server)
    @server = server
    @store = load_csv
  end

  def on_connection(connection); end

  def on_init(); end

  def classes
    @@classes
  end

  protected

  def get(key)
    @store[key]
  end

  def set(key, value)
    @store[key] = value
    write_csv(@store)
  end

  def load_csv
    raw_rows = File.read('./persistent.csv').split "\n"
    rows = raw_rows.map { |raw_row| raw_row.split("\t") }
    rows.reduce({}) { |out, row| out.merge({ row[0] => row[1] }) }
  end

  def write_csv(hash)
    rows = hash.inject([]) { |out, keyvalue| out.push(keyvalue) }
    raw_rows = rows.map { |row| row.join("\t") }
    File.write('./persistent.csv', raw_rows.join("\n"), mode: 'w')
  end
end
