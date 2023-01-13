# frozen_string_literal: true

class HomePageController < Controller
  def get
    respond_with "
# Here's a dumb guess a number game

=> /game/play
    "
  end

  def play_get
    ask_for "Think of a number between 1 and 10 (inclusive)"
  end

  def play_answer(number)
    guess = number.to_i
    if guess > 0 && guess <= 10
      answer = rand(9) + 1
      respond_with "
# The answer was #{answer}

#{answer == guess ? 'You win!' : 'You lose'}

=> /game/play Try again
    "
    else
      respond_with "
# That's not a valid number :(

=> /game/play Try again
    "
    end
  end
end
