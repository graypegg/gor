# frozen_string_literal: true

MESSAGES_PATH = './messages.txt'

class GuestbookController < Controller
  def get
    messages = File.read(MESSAGES_PATH).split("\n").reverse
    respond_with <<~TEXT
      => / 🎍 Gray's Space

      # Gray's Guestbook
      Drop a message, I needed something to test out my little rails-y Gemini framework.

      => /guestbook/sign Leave a message

      ===

      #{messages.join("\n")}


      #{use_persistent(:HitCounter).draw_counter}
    TEXT
  end

  def sign_get
    ask_for "What's your message?"
  end

  def sign_answer(response_from_user)
    message = response_from_user.gsub(/[^\w\s!?.,:)(]/, '')
    row = "#{Time.now.strftime("%d/%m/%Y %k:%M")} - #{message}\n"
    File.write(MESSAGES_PATH, row, mode: 'a')
    redirect_to '/guestbook'
  end
end