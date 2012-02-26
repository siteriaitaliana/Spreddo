require 'json'
module ParserHelper
  def parse_json (data)
    return json = JSON.parse(data)
  end

end
