# frozen_string_literal: true

# require 'bundler/setup'
require 'socket'
require 'openssl'
require 'URI'

LINE_END = "\r\n"

class Server
  def initialize(tls_context)
    raise 'Did not pass a valid TLSContext instance' unless tls_context.is_a? TLSContext

    tcp_server = TCPServer.new 1965
    @service = OpenSSL::SSL::SSLServer.new(tcp_server, tls_context.context)
  end

  def start
    loop do
      connection = Connection.new @service.accept
      Thread.new do
        app = App.new connection
        app.respond
        puts connection.as_log_entry
        connection.send
      rescue StandardError => e
        puts e
        connection.close_with_error
      end
    end
  end
end

class Connection
  attr_reader :request, :started_at, :source_ip
  attr_accessor :body, :status

  def initialize(connection)
    @connection = connection
    @request = URI connection.gets.chomp

    @started_at = Time.now
    @source_ip = @connection.peeraddr[2]

    @status = 20
    @body = ''
    @open = true

    @log_path = []
  end

  def send
    return nil unless @open
    @connection.print to_s
    close
  end

  def close
    @connection.close
    @open = false
  end

  def close_with_error
    @status = 50
    @body = ''
    send
  end

  def input
    return CGI.unescape @request.query if @request.query

    nil
  end

  def input?
    input != nil
  end

  def open?
    @open
  end

  def log_append(entity_name)
    @log_path.push entity_name
  end

  def to_s
    res = make_header
    res += @body
    res += LINE_END

    res
  end

  def as_log_entry
    "#{@started_at} | #{@source_ip}: #{@request} => #{@log_path.join '/'}\n#{self}\n"
  end

  private

  def make_header
    "#{@status} #{meta}#{LINE_END}"
  end

  def meta
    case @status
    when 10..19
      @body
    when 20..29
      'text/gemini'
    when 50..59
      'Server error or bad request'
    else
      'text/gemini'
    end
  end
end
