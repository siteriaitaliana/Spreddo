require 'simple-rss'
require 'open-uri'
require 'json'
require 'pry'
require 'uri'
require 'rest_client'

require File.dirname(__FILE__) + '/../helpers/hash.rb'
require File.dirname(__FILE__) + '/../helpers/shares_data.rb'

class HomeController < ApplicationController

  before_filter :expire_if_old_feeds, :only => [:index]
  caches_action  :index
  protect_from_forgery

  def index
    parse
  end

  def show
    @feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
  end

  def show_per_share
    @feeds = retrieve_share_news(params[:share])
    @share = params[:share]
    quote_values = show_share_quotes(share_to_sym(params[:share]))
    @change_percentuage = quote_values['cp']
    @change = quote_values['c']
    @value = quote_values['l']
    @last_time_quote = quote_values['lt']
  end

  private
  def share_to_sym(share_name)
    SharesData.load_data
    if  SharesData.FTSE100.has_value? share_name
      return SharesData.FTSE100.key(share_name).gsub('.L', '')
    else
      return share_name.gsub('.L', '')
    end
  end

  def show_share_quotes(share_symbol)
=begin
base_url = "http://query.yahooapis.com/v1/yql?q="
    query = "select * from yahoo.finance.quotes where symbol in (share_symbol)"
    val = URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    format = "&format=json"
    env = "&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
    full_url = base_url + val + format + env
###yahoo finance issue: Please provide valid credentials. OAuth oauth_problem ###
=end
    google_fin_quote = "http://finance.google.com/finance/info?client=ig&q=LON:#{share_symbol}"
    JSON.parse(RestClient.get(google_fin_quote).gsub("//","").gsub("\[","").gsub("\]",""))
    #TODO: add share info even if no rss results found
    #TODO: add red/green color when + or -
    #TODO: add ajax quote refresh real-time
  end

  def expire_if_old_feeds
      if Feed.last.created_at < Time.now - 3600
      expire_action :action => :index
    end
  end

  def parse
    rss_sources_file = File.read(File.dirname(__FILE__) + '/../helpers/rss_sources.json')
    json = JSON.parse(rss_sources_file)
    json.keys.each do |key|
      temp = SimpleRSS.parse open(json[key]['url'])
      temp.items.each do |item|
        if json[key]['source'] == 'Bloomberg'
          Feed.find_or_create_by_title(:title => item.title.force_encoding('UTF-8'), :source => json[key]['source'], :content => item.content.force_encoding('UTF-8'))
        else
          Feed.find_or_create_by_title(:title => item.title.force_encoding('UTF-8'), :source => json[key]['source'], :content => item.description.force_encoding('UTF-8'))
        end
      end
    end
    parse_rss
  end

  def parse_rss
    @matches = {}
    SharesData.load_data
    SharesData.FTSE100.flatten.each {|value| @matches[value] = scan_rss(value)}
    @matches = @matches.sort_by { |k,v| v }.reverse.first(15)
    #TODO: Link share symbol and share name search for the home and for the parser show section
  end

  def retrieve_share_news (share_name)
    share_name = Regexp.escape(share_name)
    temp_feeds ||= {}
    feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
    feeds.map do |feed|
      temp_feeds[feed.title]=feed.content unless feed.content.scan(/^#{share_name}\s|\s#{share_name}\s/i).size == 0
      temp_feeds[feed.title]=feed.content  unless feed.title.scan(/^#{share_name}\s|\s#{share_name}\s/i).size == 0
    end
    return temp_feeds
  end

  def scan_rss (regex)
    regex = Regexp.escape(regex)
    total_match = 0
    feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
    feeds.map do |feed|
      if regex == 'NEXT'
        title_match = feed.title.scan(/^#{regex}\s|\s#{regex}\s/).size
        content_match = feed.content.scan(/^#{regex}\s|\s#{regex}\s/).size
      else
        title_match = feed.title.scan(/^#{regex}\s|\s#{regex}\s/i).size
        content_match = feed.content.scan(/^#{regex}\s|\s#{regex}\s/i).size
      end
      if (title_match >= 1 || content_match >= 1)
        total_match += 1
      end
    end
    return total_match
  end

end





