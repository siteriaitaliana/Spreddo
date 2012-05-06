require 'simple-rss'
require 'open-uri'
require 'json'
require 'pry'

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
  end

  private
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
    alias_share_name = SharesData.FTSE100.each {|value| }
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
      title_match = feed.title.scan(/^#{regex}\s|\s#{regex}\s/i).size
      content_match = feed.content.scan(/^#{regex}\s|\s#{regex}\s/i).size
      if (title_match >= 1 || content_match >= 1)
        total_match += 1
      end
    end
    return total_match
  end

end





