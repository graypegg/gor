# frozen_string_literal: true

class HomePageController < Controller
  def get
    respond_with "
# 🎍 Gray's space
Giving Gemini a try! It feels cozy. <3

## Gemini on Rails
So I've built out a little Ruby framework for the Gemini protocol. It's serving this site you're on now! I'll prove it, the time is #{Time.now} and the current scope is #{self.class}. (Values included in a template, how very Web1.0!) It's quite simple at the moment, with basically just controllers for responding to 'get' (no query string) and 'answer' (with query string) requests in a rails-y looking syntax.

I'll clean some stuff up this weekend so I can share what I have! Keep an eye on this space.

## Me
I'm a developer in Montréal. Part time red panda. I'll have to host some art on here or something soon. Furry stuff feels like it would fit well in a small-internet zone like this. Learning Elixir at the moment, but I'm most comfy with Ruby and Typescript.

## Links

=> /guestbook


#{use_persistent(:HitCounter).draw_counter}
"
  end
end

