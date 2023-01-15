# frozen_string_literal: true

ROBOTS_TXT = File.read('./config/robots.txt')

class App
  attr_reader :persistent_instances

  def initialize(connection, persistent_instances)
    raise 'Did not pass a valid connection' unless connection.is_a? Connection
    raise 'Connection is already closed' unless connection.open?

    @connection = connection
    @persistent_instances = persistent_instances
  end

  def respond
    return if handle_special_requests

    segments = split_path_by_segments @connection.request.path
    begin
      route = segments[1]
    rescue StandardError
      route = nil
    end
    controller = CONTROLLERS[route]

    if controller
      instance = Kernel.const_get(controller).new self

      action = segments[2]

      action = nil if action == ''

      answer_symbol = "#{action}_answer" if action
      answer_symbol = 'answer' unless action
      get_symbol = "#{action}_get" if action
      get_symbol = 'get' unless action

      if @connection.input? && instance.respond_to?(answer_symbol.to_sym)
        @connection.log_append "#{controller}##{answer_symbol}"
        response = instance.send answer_symbol.to_sym, @connection.input
      elsif !@connection.input? && instance.respond_to?(get_symbol.to_sym)
        @connection.log_append "#{controller}##{get_symbol}"
        response = instance.send get_symbol.to_sym
      else
        @connection.close_with_error 51
      end

      if response
        @connection.status = response.status
        @connection.body = response.body
      end

      @connection.send unless @connection.open?
    else
      @connection.close_with_error 51
    end
  end

  private

  def handle_special_requests
    case @connection.request.path
    when '/robots.txt'
      @connection.body = (ROBOTS_TXT || '*')
      @connection.status = 20
      @connection.mime_type = 'text/plain'
      @connection.send
      return true
    end

    false
  end

  def split_path_by_segments(path)
    path.match %r{/([\w-]*)/?([\w-]*)?}
  end
end
