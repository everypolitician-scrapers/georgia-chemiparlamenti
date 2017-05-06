#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

class Scraper
  require 'scraped'

  def initialize(h)
    args = h.to_a
    @url, @klass = args.shift
    @conf = args.to_h
  end

  def scraped
    @scraped ||= klass.new(response: Scraped::Request.new(url: url).response)
  end

  def data
    defaults.merge(scraped.to_h)
  end

  private

  attr_reader :url, :klass, :conf

  def defaults
    @conf[:defaults] || {}
  end
end

class ScraperRun
  require 'scraperwiki'

  def initialize(table: 'data', unique_by: 'id', debug: false)
    @table = table
    @unique_by = unique_by
    @debug = debug
  end

  def save(rows)
    rows.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if debug
    ScraperWiki.sqliteexecute('DROP TABLE %s' % table) rescue nil
    ScraperWiki.save_sqlite(unique_by, rows)
  end

  private

  attr_reader :table, :unique_by, :debug
end

start = 'http://www.chemiparlamenti.ge/en/parliamentarians'
data = Scraper.new(start => MembersPage).scraped.member_urls.map do |url|
  Scraper.new(url => MemberPage, defaults: { term: 9 }).data
end

ScraperRun.new(unique_by: %i[id term], debug: ENV['MORPH_DEBUG']).save(data)
