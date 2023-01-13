# frozen_string_literal: true

class HomePageController < Controller
  def get
    respond_with "Did this work?"
  end

  def answer(question)
    redirect_to '/'
  end
end
