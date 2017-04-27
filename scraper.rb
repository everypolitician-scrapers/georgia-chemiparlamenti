#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

require 'scraped'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.xpath('//a[@data-mp-id]/@href').map(&:text).uniq
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.split('/').last
  end

  field :name do
    box.css('h4').text.tidy
  end

  field :birth_date do
    noko.xpath('//h3[.="Birth Date / Place"]/following::p').map(&:text).map(&:tidy).first[/(\d{4}-\d{2}-\d{2})/, 1]
  end

  field :email do
    noko.css('img[src*="sms.png"] + p').text.tidy
  end

  field :party do
    box.css('h4 + p').text.tidy
  end

  field :start_date do
    mandate.first
  end

  field :end_date do
    return '' if mandate.last == 'Current'
    mandate.last
  end

  field :area do
    noko.xpath('//h3[.="Electoral District"]/following::p').map(&:text).map(&:tidy).first
  end

  field :area_id do
    area.to_s[/#(\d+)/, 1]
  end

  private

  def box
    noko.css('div.mp-columns')
  end

  def mandate
    noko.at_xpath('//h3[.="Date of Terminition of Mandate"]/following::p').text.tidy
        .gsub('Current', '').split('- ').map(&:tidy)
  end
end

def scraper(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

start = 'http://www.chemiparlamenti.ge/en/parliamentarians'
data = scraper(start => MembersPage).member_urls.map do |url|
  scraper(url => MemberPage).to_h.merge(term: 9)
end

# data.each { |r| puts r.reject { |k,v| v.to_s.empty? }.sort_by { |k,v| k }.to_h }
ScraperWiki.save_sqlite(%i[id term], data)
