
require File.dirname(__FILE__) + '/../helpers/hash.rb'
require File.dirname(__FILE__) + '/../helpers/shares_data.rb'

class HomeController < ApplicationController
  caches_page :index

  def index
    ParserController.parse
    parse_rss
  end

  def scan_rss (regex)
    total_match = 0
    feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
    feeds.map do |feed|
      total_match += feed.content.downcase.scan(/#{regex.downcase}\s|\s#{regex.downcase}\s/).size
      total_match += feed.title.downcase.scan(/#{regex.downcase}\s|\s#{regex.downcase}\s/).size
    end
    return total_match
  end

  def parse_rss
    @matches ||= {}
    SharesData.load_data
    SharesData.FTSE100.flatten.each {|value| @matches[value] = scan_rss(value)}
  end

end
