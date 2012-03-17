
require File.dirname(__FILE__) + '/../helpers/hash.rb'
require File.dirname(__FILE__) + '/../helpers/shares_data.rb'

class HomeController < ApplicationController
  caches_page :index

  def index
    ParserController.parse
    parse_rss
  end

  private

  def scan_rss (regex)
    regex = Regexp.escape(regex)
    total_match = 0
    feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
    feeds.map do |feed|
      title_match = feed.title.scan(/^#{regex}\s|\s#{regex}\s/i).size
      content_match = feed.content.scan(/^#{regex}\s|\s#{regex}\s/i).size
      if (title_match >= 1 || content_match >= 1)
        total_match += 1
      end
    end
    return total_match
  end

  def parse_rss
    @matches ||= {}
    SharesData.load_data
    SharesData.FTSE100.flatten.each {|value| @matches[value] = scan_rss(value)}
    #TODO: Link share symbol and share name search for the home and for the parser show section
  end

end
