# frozen_string_literal: true

class App
  def initialize(connection)
    raise 'Did not pass a valid connection' unless connection.is_a? Connection
    raise 'Connection is already closed' unless connection.open?

    @connection = connection
  end

  def respond
    controller = CONTROLLERS[@connection.request.path]
    if controller
      instance = Kernel.const_get(controller).new self

      if @connection.input? && instance.respond_to?(:answer)
        @connection.log_append "#{controller}#answer"
        response = instance.answer @connection.input
      elsif !@connection.input? && instance.respond_to?(:get)
        @connection.log_append "#{controller}#get"
        response = instance.get
      end

      if response
        @connection.status = response.status
        @connection.body = response.body
      end

      @connection.send unless @connection.open?
    else
      connection.close_with_error
    end
  end
end
