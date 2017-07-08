require 'telegram/bot'
require 'open-uri'
require 'nokogiri'
require 'uri'


DEFUALT_LINK = 'https://kudago.com'
HELP = 'Если не знаешь куда пойти в Минске, напиши тип заведения или развлечения'\
       'и я подскажу тебе пару местечек(Кафе, Ресторан, Бассейн..)'

# class for entertainments and places

class Entertainment
  attr_accessor :name
  attr_accessor :address
  attr_accessor :description
  attr_accessor :image

  def attributs_from_hash hash
    @name = hash['name']
    @address = hash['address']
    @description = hash['description']
    @image = hash['image']
    return self
  end

  def to_s
    "#{@name}\n\n#{@description}\n#{@address}\n#{@image}"
  end
end

# This method extracts the necessary parameters from the  html block
# parameter: block of html code
# result: hash with 4 values

def get_hash_item_description post
  description_block = post.at_css('div[class="post-list-item-description"]')

  begin
    description_block.at_css('address').text.strip
  rescue
    return {}
  end

  tegs = {
    'name' => description_block.at_css('h4').text.strip,
    'address' => address = description_block.at_css('address').text.strip,
    'description' => description_block.at_css('p').text,
    'image' => DEFUALT_LINK + post.at_css('img')['src']
  }
end

# This method retrieves elements from the html document
# parameter: html document
# result: array of elements

def parsing(doc)
  entertainments = []
  doc.css('li[class="post-list-item feed-child"]').each do |item|
    hashed_item = get_hash_item_description item
    entert = Entertainment.new
    entert.attributs_from_hash(hashed_item)
    entertainments.push entert unless entert.to_s == "\n\n\n\n"
  end
  return entertainments
end

# do request to a server with a parameter url
# parameter: url
# result: html doc

def do_request url
  html = open(URI::encode url)
  doc = Nokogiri::HTML(html)
end

# Gets the client request results from the server and sends them to the client
# parameters: Bot object, message from Client
# result: nil

def suggest_entartainmant(bot, message)
  url = "https://kudago.com/search/?location=mns&q="

  begin
    url += message.text
  rescue
  end

  proposals = parsing do_request url
  proposals = ['Не слышал о таком'] if proposals.empty?
  proposals.map { |e| bot.api.sendMessage(chat_id: message.chat.id, text: e.to_s) }
end

token = File.open('token_file', 'r'){ |file| file.read }.strip

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.sendMessage(chat_id: message.chat.id, text: 'Hello.' + HELP)
    when '/help'
      bot.api.sendMessage(chat_id: message.chat.id, text: HELP)
    else
      suggest_entartainmant bot, message
    end
  end
end
