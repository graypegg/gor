# frozen_string_literal: true

class App
  attr_reader :connection

  def initialize(connection)
    raise 'Did not pass a valid conenction' unless connection.is_a? Connection
    raise 'Connection is already closed' unless connection.open?

    @connection = connection
  end

  def respond
    controller = CONTROLLERS[@connection.request.path]
    if controller
      instance = Kernel.const_get(controller).new self
      @connection.body = instance.respond
      @connection.send unless @connection.open?
    else
      connection.close_with_error
    end
  end
end

class Controller
  attr_reader :app

  def initialize(app)
    raise 'Did not pass a valid app' unless app.is_a? App

    @app = app
  end

  def respond
    "20 OK :)"
  end

  protected

  def ask_for(prompt)
    @app.connection.status = 10
    prompt
  end
end
