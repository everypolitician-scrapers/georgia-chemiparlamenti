#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

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
