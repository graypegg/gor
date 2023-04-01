# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"
require "html_to_plain_text"
require "nokogiri"
require "rainbow"
require "open-uri"

HTTPGraphQL = GraphQL::Client::HTTP.new("https://kobohn.fly.dev/graphql")
Schema = GraphQL::Client.load_schema(HTTPGraphQL)
Client = GraphQL::Client.new(schema: Schema, execute: HTTPGraphQL)

ListQuery = Client.parse <<~GRAPHQL
  query($page: Int) {
    topItems {
      data(page: $page) {
        title
        id
        url
        text
        score
        by
        time
        kids {
          recordTotal
        }
      }
      recordTotal
    } 
  }
GRAPHQL

ItemQuery = Client.parse <<~GRAPHQL
  query($id: Int!, $page: Int) {
    item (id: $id){
      title
      id
      url
      text
      score
      by
      time
      kids {
        data (page: $page) {
        title
        id
        url
        text
        score
        by
        time
          kids {
            recordTotal
          }
        }
        recordTotal
      }
    }
  }
GRAPHQL

def slugify(item)
  item['id']
end

def html_to_gem(html)
  page = Nokogiri::HTML5(html)
  page.css('h1').each do |title|
    title.content = "# #{title.content}"
  end
  page.css('h2').each do |title|
    title.content = "## #{title.content}"
  end
  page.css('h3').each do |title|
    title.content = "### #{title.content}"
  end
  page.search('//a/preceding-sibling::text()[1]').each do |text|
    matches = text.to_html.match(/\[\d\]/)
    if (matches)
      text.next_sibling.content = "#{matches[0]} → #{text.next_sibling.content}"
      text.content = text.content.gsub(matches[0], '')
    end
  end
  page.css('a').each do |link|
    return unless link[:href]
    replacement = Nokogiri::XML::Node.new("p", page)
    replacement.content = "\n=> #{link[:href]} #{link.content}\n"
    link.add_next_sibling replacement
    link.remove
  end
  page.css('pre').each do |pre|
    pre.content = "```\n#{pre.content}\n```\n"
  end
  HtmlToPlainText.plain_text(page.to_html)
end

class ItemComponent
  def initialize(item, is_lower: nil)
    is_lower ||= false
    return nil unless item.is_a? Hash
    @item = item
    @is_lower = is_lower
  end

  def render
    puts @item['title']
    prefix = '## ' unless @is_lower
    prefix = '### ' if @is_lower
    <<~TEXT
      #{"#{prefix}#{@item['title']}" if @item['title']}#{"#{prefix}#{@item['by']}" if @is_lower && @item['by']}#{"\n↑ #{@item['score']}" if @item['score']}#{" #{@item['by']}" if !@is_lower && @item['by']}#{"\n" + html_to_gem(@item['text']) unless @item['text'].nil?}
    TEXT
  end
end

class CommentComponent
  def initialize(item)
    return nil unless item.is_a? Hash
    @item = item
  end

  def render
    <<~TEXT
      #{ItemComponent.new(@item, is_lower: true).render}#{"\n=> /hn/comments?#{slugify @item} View #{@item['kids']['recordTotal']} Replies" if @item['kids'] && @item['kids']['recordTotal'] > 0}


    TEXT
  end
end

class ListItemComponent
  def initialize(item)
    return nil unless item.is_a? Hash
    @item = item
  end

  def render
    <<~TEXT
      #{ItemComponent.new(@item).render[..-2]}
      => /hn/comments?#{slugify @item} View #{@item['kids']['recordTotal']} Comments
      => /hn/view?#{slugify @item} View in Gemtext
      => #{@item['url']} Open with HTTP

    TEXT
  end
end

class HNController < Controller
  def get
    list_view
  end

  def answer(page)
    return list_view(page.to_i) if page.to_i.is_a? Integer
    list_view
  end

  def comments_answer(query)
    id = query.split('&')[0].to_i
    page = query.split('&')[1].to_i unless query.split('&')[1].nil?
    page ||= 1
    result = Client.query(ItemQuery, variables: { id: id.to_i, page: page })
    item = result.to_h['data']['item']
    comments = item['kids']['data']
    respond_with <<~TEXT
      #{build_header}
      #{ItemComponent.new(item, is_lower: !item['title']).render}
      #{'- ' * 50}

      #{comments.map { |comment| CommentComponent.new(comment).render }.join}

      => /hn/comments?#{id}&#{page + 1} Next
      #{"=> /hn/comments?#{id}&#{page - 1} Prev" if page > 1}
      => /hn/comments?#{id} Back to Page 1
    TEXT
  end

  def view_answer(id)
    begin
      id = id.to_i
      result = Client.query(ItemQuery, variables: { id: id })
      url = result.to_h['data']['item']['url']
      doc = URI.open(url)
      respond_with <<~TEXT
        #{html_to_gem doc}
      TEXT
    rescue
      ControllerResponse.new 50, <<~TEXT
        Something went wrong while trying to parse the target site.
      TEXT
    end
  end

  private

  def build_header
    <<~TEXT
      ```
      #{Rainbow(' Y ').ivory.bold.bg(:orange)} #{Rainbow(" Hacker News#{' ' * (100 - 15)}").black.bg(:orange)}
      ```
    TEXT
  end

  def build_footer
    <<~TEXT
      ```
                                                    ...
      ```

      Captured as of #{Time.now.strftime "%F %R (%:z)"}
      Content pulled from news.ycombinator.com, via kobohn.fly.dev.
      => / 🎍 Gray's space
    TEXT
  end

  def list_view(page = 1)
    begin
      result = Client.query(ListQuery, variables: { page: })
      items = result.to_h['data']['topItems']['data']
      respond_with <<~TEXT
        #{build_header}
        # Hacker News (news.ycombinator.com)
        is a link sharing site with a focus on sparking interest in it's users. The following entries are ordered by their upvote rating, but this capsule does not support logging in, so it's read-only here. Some content can be viewed in Gemtext, but not (even nearly) all content.
        
        Page #{page} / #{result.to_h['data']['topItems']['recordTotal']}

        #{items.map { |item| ListItemComponent.new(item).render }.join "\n"}
        ```
                                                      ...
        ```
        => /hn?#{page + 1} Next
        #{"=> /hn?#{page - 1} Prev" if page > 1}
        => /hn Back to Page 1

        #{build_footer}
      TEXT
    rescue
      respond_with <<~TEXT
        #{build_header}

        Something is broken. You should check if KoboHN is down. It's the source of the API for this capsule.

        => https://kobohn.fly.dev
        #{build_footer}
      TEXT
    end
  end

end

