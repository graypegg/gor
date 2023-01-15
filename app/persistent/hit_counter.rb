# frozen_string_literal: true

class HitCounter < Persistent
  def on_connection(_connection)
    @count = get('hitcount').to_i || 0
    @count += 1
    set('hitcount', @count)
  end

  def draw_counter
    content = " #{@count} hits "
    top = "┌#{'─' * content.length}┐"
    middle = "│#{content}│"
    bottom = "└#{'─' * content.length}┘"

    "```\n#{top}\n#{middle}\n#{bottom}\n```\n"
  end
end
