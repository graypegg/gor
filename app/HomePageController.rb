# frozen_string_literal: true

class HomePageController < Controller
  def respond
    @app.connection.log_append 'HomePageController'

    "Did this work?"
  end
end
