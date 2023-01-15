# frozen_string_literal: true
require 'rouge'

class GORController < Controller
  def get; homepage(false) end
  def answer; homepage(true) end

  def persistents_get; persistents_page(false) end
  def persistents_answer; persistents_page(true) end

  def connections_get; connections_page(false) end
  def connections_answer; connections_page(true) end

  def controllers_get; controllers_page(false) end
  def controllers_answer; controllers_page(true) end

  private

  def homepage(highlight)
    respond_with <<~TEXT
      => / 🎍 Gray's Space

      # Gemini on Rails
      So I've built out a little Ruby framework for the Gemini protocol. It's serving this site you're on now! I'll prove it, the time is #{Time.now} and the current scope is #{self.class}. (Values included in a template, how very Web1.0!) It's quite simple at the moment, with basically just controllers for responding to 'get' (no query string) and 'answer' (with query string) requests in a rails-y looking syntax.

      ## Repo
      This is the only repo currently. It's just my gemini capsule. This will change in the future with a more clean slate to start from.
      => https://github.com/graypegg/gor github

      ## Internals
      .
      ├── app/
      │   ├── persistent/
      │   │   ├── # Objects instantiated at server start up,
      │   │   ├── # and persist between connections
      │   │   └── 💎 hit_counter.rb
      │   │
      │   ├── # Controllers are included here, they cannot be nested
      │   ├── 💎 gor_controller.rb
      │   ├── 💎 guestbook_controller.rb
      │   └── 💎 home_page_controller.rb
      │
      ├── config/
      │   ├── # Some configuration files
      │   ├── 📄 robots.txt
      │   ├── 💎 routes.rb
      │   └── 💎 tls.rb
      │
      ├── framework/
      │   └── ... guts in here ...
      │
      └── 🧾 persistent.csv
          ├ # A tab-seperated file. There's an abstraction for writing
          └ # to this file in the Persistent class.

      ## Docs
      ### /app
      => /gor/persistents#{link_suffix(highlight)} Persistents
      => /gor/controllers#{link_suffix(highlight)} Controllers

      ### Other
      => /gor/connections#{link_suffix(highlight)} Connections
    TEXT
  end

  def persistents_page(highlight)
    respond_with <<~TEXT
            #{generate_header highlight}
            # Persistents
            are my half-baked idea around how to handle 'view models' in a way that doesn't require too much over head. You can think of it as a way to handle one 'atom' of data. It has hooks to handle when connections happen, and the ability to be imported into controllers to use or update that value.

            There's some utility methods included in the Persistent class to write to a csv file, but you could just as easily use volatile memory and store everything in instance vars if you want.

            You can make a persistent by just adding a new file in /app/persistent. It will be loaded automatically. A simple persistent looks like the following:

            ```
            #{generate_code_block 'app/persistents/hit_counter.rb', 'rb', highlight, "
class HitCounter < Persistent
  def on_connection(_connection)
    @count = get('hitcount').to_i || 0
    @count += 1
    set('hitcount', @count)
  end

  def draw_counter
    \"\#{@count} hits\"
  end
end
            "}
            ```

            This can then be used in a controller, using the 'Controller#use_persistent' method, which gets you the server's current instance of that persistent as in the following toy example.
            => /gor/controllers#{link_suffix(highlight)} See Controllers

            ```
            #{generate_code_block 'app/home_page_controller.rb', 'rb', highlight, "
class HomePageController < Controller
  def get
    respond_with <<~TEXT
      # Gray's space

      \#{use_persistent(:HitCounter).draw_counter}
    TEXT
  end
end
            "}
            ```

            which renders our hit counter on screen, like the following

            ```
            #{generate_code_block 'Output', 'md', highlight, "
# Gray's space

2 hits
            "}
            ```

            ## API

            ### Persistent#on_connection
            > def on_connection(conn); end

            Shadow this method in your class that extends Persistent to have a hook when a new connection is created. The current connection is passed.
            => /gor/connections#{link_suffix(highlight)} See Connection

            ### Persistent#on_init
            > def on_init(); end

            Shadow this method in your class that extends Persistent to have a hook when the server first starts up.

            ### Persistent#get
            > get(key)

            Gets a value from the persistent.csv key-value store. The key must be a string. The value returned will be either a string or nil.

            ### Persistent#set
            > set(key, value)

            Write a value to the persistent.csv key-value store. The key must be a string. The value will be .to_s'd before storing it. There's nothing stopping you from storing JSON if you'd like.
    TEXT
  end

  def connections_page(highlight)
    respond_with <<~TEXT
      #{generate_header highlight}
      # Connections
      represent the current connection to the client, and are generally something you won't have to deal with except inside implementations of Persistent#on_conncetion.
      => /gor/persistents#{link_suffix(highlight)} See Persistent
      
      ## API

      ### Connection#request
      > conn.request

      The request from the client, as parsed by Ruby's URI module. Gemini clients only send a URI to servers, so this is all the information we have about the client.
      => https://ruby-doc.org/stdlib-3.0.1/libdoc/uri/rdoc/URI.html See Ruby Docs on URI

      ### Connection#body= / Connection#body
      > conn.body = 'Hi'
      > conn.body

      Sets or gets the current body that will be sent when this transaction completes. The body can be anything textual, but no binary data is allowed.

      ### Connection#mime_type= / Connection#mime_type
      > conn.mime_type = 'text/plain'
      > conn.mime_type

      Sets or gets the current body that will be sent when this transaction completes. The body can be anything textual, but no binary data is allowed.

      ### Connection#status= / Connection#status
      > conn.status = 51
      > conn.status

      Sets or gets the current Gemini status code that will be sent when this transaction completes. This should be an integer.
      => gemini://gemini.circumlunar.space/docs/specification.gmi See Gemini spec, Section 3.2 Status codes

      ### Connection#send
      > conn.send

      Sends the current body + status for this connection to the client, and closes the connection. Note that you can only send once, and future calls to send on this connection will do nothing. This allows you to stub connections in a presistent if you'd like.

      ### Connection#started_at
      > conn.started_at

      Timestamp of when this connection was initially processed. It's a standard Ruby Time object

      ### Connection#source_ip
      > conn.source_ip

      The originating IP for this connection in a string. Useful for IP blocking.
    TEXT
  end

  def controllers_page(highlight)
    respond_with <<~TEXT
      #{generate_header highlight}
      # Controllers
      are actually views and controllers in one. I decided for such a simple protocol, it's better to just inline styles rather than adding a whole other template system. We already have string interpolation in Ruby! (You are of course free to use File.read to load any files you wish to send to clients)

      Controllers should be direct children in the file tree under /app and have a file name that ends with _controller. You cannot nest controllers. Controllers manage their route with any number of actions. Actions are methods in side your controller.

      A simple example would be a simple static document, here we extend Controller, and define our own methods, HelloController#get, HelloController#greet_get and HelloController#greet_answer. We'll assume we assigned this controller to the route "hello" in /config/routes.rb.
     
      ```
      #{generate_code_block 'app/hello_controller.rb', 'rb', highlight, "
class HelloController < Controller
  # /hello
  def get
    respond_with <<~TEXT
      # 🎍 Gray's space
      Giving Gemini a try! It feels cozy. <3

      => /hello/greet Get a personalized hello
    TEXT
  end

  # /hello/greet
  def greet_get
    ask_for \"What's your name?\"
  end

  # /hello/greet?name_will_be_here
  def greet_answer(name)
    respond_with <<~TEXT
      Hello \#{name}!
    TEXT
  end
end    
      "}
      ```

      * The HelloController#get method will be called when the route assigned to the controller is requested. Importantly, it will NOT be called if there's a user response on the request. (a ? in the URI)
      
      * The HelloController#greet_get is similar, but will only be called when the greet action is requested on this controller. That means the route would be something like /hello/greet. It uses the Controller#ask_for method to send back a question popup. The user can enter a string and send back. It will be passed to the *_answer method that has the name action name.
      
      * The HelloController#greet_answer method will only be called when /hello/greet?something is called. There must be a user input value. It's passed as a string as the only param.

      You can include as many actions as you want! Private methods will not be accessible from the Gemini service, so you can keep things DRY by keeping common logic in private methods.

      Note: A controller is always instantiated fresh for every connection. You cannot keep data between requests in this class. Use a persistent for that.
      => /gor/persistents#{link_suffix(highlight)} See Persistents

      You assign controllers to routes using the /config/routes.rb file.

      ## API

      ### Controller#respond_with
      > respond_with "Hello"

      Respond to client with a text/gemini response. The gemini status code will be 20. You may want to use multiline comments like <<~TEXT to make things a little cleaner.
      This MUST be the return statement in your action for it to work.

      ### Controller#ask_for
      > ask_for "What is your age?"

      Sends back a request to the user to provide a string. You can include a question to be shown on the client. The gemini status will be 10.
      This MUST be the return statement in your action for it to work.

      ### Controller#redirect_to
      > redirect_to "gemini://gem.graypegg.com"

      Sends back a redirect to the client. This will normally ask the user if they want to be redirect.
      This MUST be the return statement in your action for it to work.

      ### Controller#use_persistent
      > use_persistent(:GuestbookPersistent).all_messages

      Gets the current instance of a persistent.
      => /gor/persistents#{link_suffix(highlight)} See Persistents

      ### Controller#get / Controller#*_get
      > def get; end
      > def ailurus_get; end

      Controller action for requests with no user input data. (No ? in the URI)

      ### Controller#answer / Controller#*_answer
      > def answer(input); end
      > def fulgens_answer(input); end

      Controller action for requests with user input data. (that have a ? in the URI)
    TEXT
  end
  def generate_code_block(name, file_type, should_highlight, code)
    longest_line_length = code.split("\n").sort_by(&:length).reverse[0].length
    code = (code.strip.split("\n").map { |line| "   #{line}" }).join "\n"
    top_fence_title = "┤ #{name} ├─"
    top_fence = '╭' + ('─' * (longest_line_length - top_fence_title.length + 6)) + top_fence_title + '╮'
    bottom_fence = '╰' + ('─' * (longest_line_length + 6)) + '╯'
    if should_highlight
      lexer = Rouge::Lexer.find(file_type)
      formatter = Rouge::Formatters::Terminal256.new

      body = formatter.format(lexer.lex(code))
    else
      body = code
    end
    <<~TEXT
      #{top_fence}

      #{body}

      #{bottom_fence}
    TEXT
  end

  def generate_header(should_highlight)
    <<~TEXT
      => / 🎍 Gray's Space (Root)
      => /gor#{link_suffix(should_highlight)} <-- Back

      => #{current_path}#{link_suffix(!should_highlight)} #{should_highlight ? 'Turn off' : 'Turn on'} syntax highlighting
    TEXT
  end

  def link_suffix(should_highlight)
    should_highlight ? '?highlight' : ''
  end
end
