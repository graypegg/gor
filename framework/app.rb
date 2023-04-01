# frozen_string_literal: true

ROBOTS_TXT = File.read('./config/robots.txt')

class App
  attr_reader :persistent_instances, :connection

  def initialize(connection, persistent_instances)
    raise 'Did not pass a valid connection' unless connection.is_a? Connection
    raise 'Connection is already closed' unless connection.open?

    @connection = connection
    @persistent_instances = persistent_instances
  end

  def respond
    return if handle_special_requests

    controller_class = requested_controller

    if controller_class
      action_symbol, controller_instance = find_requested_action(controller_class)

      if action_symbol
        @connection.log_append "#{controller_class}##{action_symbol}"
        action_method = controller_instance.method(action_symbol)
        response = controller_instance.send action_symbol, @connection.input if action_method.arity == 1
        response = controller_instance.send action_symbol if action_method.arity.zero?
      else
        @connection.close_with_error 51
      end
    end

    if response
      @connection.status = response.status
      @connection.body = response.body
      @connection.send unless @connection.open?
    else
      @connection.close_with_error 51
    end
  end

  private

  def find_requested_action(controller)
    controller_instance = controller.new self

    action_segment = segments[:action]
    action_segment = nil if action_segment == ''

    answer_method_name = "#{action_segment}_answer" if action_segment
    answer_method_name = 'answer' unless action_segment
    get_method_name = "#{action_segment}_get" if action_segment
    get_method_name = 'get' unless action_segment

    is_answer_request = @connection.input? && controller_instance.respond_to?(answer_method_name.to_sym)
    is_get_request = !@connection.input? && controller_instance.respond_to?(get_method_name.to_sym)

    action_symbol = if is_answer_request
                      answer_method_name.to_sym
                    elsif is_get_request
                      get_method_name.to_sym
                    end
    [action_symbol, controller_instance]
  end

  def requested_controller
    begin
      route = segments[:controller]
    rescue StandardError
      route = nil
    end
    CONTROLLERS[route]
  end

  def segments
    begin
      segments = split_path_by_segments (@connection.request.path + '/')
      segments = [] unless segments.is_a? MatchData
      segments = segments.to_a.map { |segment| segment.gsub(/\W/, '') }
    rescue StandardError
      segments = []
    end
    {
      controller: segments[1] || nil,
      action: segments[2] || nil
    }
  end

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
