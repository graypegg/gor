# frozen_string_literal: true

POSTS = [
  "
# Furnal Equinox 2023
## 31.03.2023

It's been over a week since FE now! Wow. The whole weekend for me went by really quickly. I think getting to wear Toish (my big red panda plushie fursuit) was defintitely the highlight. Having only had him thru the pandemic really, any chance I get to wear him is fun!

We stayed at the Delta hotel, down the way from the convention. Maybe a 10 min walk? Not really that bad. And Toish packs into 3 duffel bags to be carted back and forth. Hotel was lovely, nothing to complain about there.

The con was AMAZING as it always is. I got some prints, and a little bismuth bird statue in the dealers den, like normal, things I would never think to buy until I see them. Haha. Walking around with folks in suit a lot, and getting out side to the Jack Layton statue (multiple times) for pictures. I'll need to include some on this gemini instance. Remind me to add that to the ruby app this is running on.

This was my second time back in toronto after moving to montreal, was good to see some old friends from around there. Especially Pup Winter! Got some time with him at the Brickworks ciderhouse on queen street after the con. Lovely time.

This is a rambling blog post, so hopefully it's not too cringe-inducing. Just trying to set up blog posts in this ruby app and I needed content. So there, we have ✨ content ✨.
",
]

def get_link_name_for_post(post)
  post.lines[1][2..].downcase.gsub(/\s/, '_').gsub(/\W/, '')[0..-2]
end

class BlogController < Controller
  POSTS.each do |post|
    define_method("#{get_link_name_for_post(post)}_get") do
      respond_with <<~TEXT
        => / 🎍 Gray's space
        => /thoughts back to list

        #{post}

        #{use_persistent(:HitCounter).draw_counter}
      TEXT
    end
  end

  def get
    respond_with <<~TEXT
      => / 🎍 Gray's space

      #{get_links}
    TEXT
  end

  private

  def get_links
    (POSTS.map do |post|
      "=> /thoughts/#{get_link_name_for_post post} #{post.lines[1][2..]}"
    end).join "\n"
  end
end

