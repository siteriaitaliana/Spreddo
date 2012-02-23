require 'simple-rss'
require 'open-uri'

class ParserController < ApplicationController
  def show

    @bloomberg_rss = SimpleRSS.parse open('http://inside.bloomberg.com/blog/atom.xml')
    @yahoo_finance_banking = SimpleRSS.parse open('http://finance.yahoo.com/rss/banking')
    @ft_uk = SimpleRSS.parse open('http://www.ft.com/rss/home/uk')
    @ft_companies = SimpleRSS.parse open('http://www.ft.com/rss/companies')


    @bloomberg_rss.items.each do |item|
      #feed = Feed.new(:source => "Bloomberg", :title => item.title, :content => item.content)
      Feed.find_or_create_by_title(:title => item.title, :source => "Bloomberg", :content => item.content )
    end

    @yahoo_finance_banking.items.each do |item|
      Feed.find_or_create_by_title(:source => "YahooFinanceBanking", :title => item.title, :content => item.description)
    end

    @ft_uk.items.each do |item|
      Feed.find_or_create_by_title(:source => "FinancialTimes_UK", :title => item.title, :content => item.description)
    end

    @ft_companies.items.each do |item|
      Feed.find_or_create_by_title(:source => "FinancialTimes_Companies", :title => item.title, :content => item.description)
    end

  end
end
