require 'simple-rss'
require 'open-uri'
require 'json'

class ParserController < ApplicationController
  caches_page :index
  def show
    @feeds = Feed.all(:order => "source", :conditions => ["DATE(created_at) = DATE(?)", Time.now], :order => "created_at")
  end

  def self.parse
    rss_sources_file = File.read(File.dirname(__FILE__) + '/../helpers/rss_sources.json')
    json = JSON.parse(rss_sources_file)
    @feeds ||= []
    json.keys.each do |key|

      @temp = SimpleRSS.parse open(json[key]['url'])

      @temp.items.each do |item|
        if json[key]['source'] == 'Bloomberg'
          Feed.find_or_create_by_title(:title => item.title.force_encoding('UTF-8'), :source => json[key]['source'].force_encoding('UTF-8'), :content => item.content.force_encoding("UTF-8"))
        else
          Feed.find_or_create_by_title(:title => item.title.force_encoding('UTF-8'), :source => json[key]['source'].force_encoding('UTF-8'), :content => item.description.force_encoding("UTF-8"))
        end
      end
    end
  end

end
