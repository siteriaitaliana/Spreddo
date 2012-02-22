require 'simple-rss'
require 'open-uri'

class HomeController < ApplicationController

  def index
    @rss = SimpleRSS.parse open('http://inside.bloomberg.com/blog/atom.xml')


  end


end
