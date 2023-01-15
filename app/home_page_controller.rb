# frozen_string_literal: true

class HomePageController < Controller
  def get
    respond_with "
# 🎍 Gray's space
Giving Gemini a try! It feels cozy. <3

## Me
I'm a developer in Montréal. Part time red panda. I'll have to host some art on here or something soon. Furry stuff feels like it would fit well in a small-internet zone like this. Learning Elixir at the moment, but I'm most comfy with Ruby and Typescript.

## Links

=> /guestbook
=> /gor /gemini-on-rails


#{use_persistent(:HitCounter).draw_counter}
"
  end

end

