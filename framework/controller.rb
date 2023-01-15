# frozen_string_literal: true

class Controller
  attr_reader :app

  def initialize(app)
    raise 'Did not pass a valid app' unless app.is_a? App

    @app = app
  end

  def get
    respond_with "20 OK :)"
  end

  def answer(response_from_user)
    self.get
  end

  protected

  def use_persistent(name)
    raise "You must pass a symbol for a persistent name" unless name.is_a? Symbol

    @app.persistent_instances.find { |instance| instance.class.name == name.to_s }
  end

  def ask_for(prompt)
    ControllerResponse.new 10, prompt
  end

  def respond_with(body)
    ControllerResponse.new 20, body
  end

  def redirect_to(path)
    ControllerResponse.new 30, path
  end
end

class ControllerResponse
  attr_reader :status, :body

  def initialize(status, body)
    @status = status
    @body = body
  end
end