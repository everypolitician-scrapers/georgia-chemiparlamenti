#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

module EveryPolitician
  class ScrapedPage
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
      scraped.to_h
    end

    private

    attr_reader :url, :klass, :conf
  end

  class ScraperRun
    require 'scraperwiki'

    # TODO: add a runid (default to UUID? Or auto-inc?) + start_time
    def initialize(table: 'data', unique_by: 'id', debug: false)
      @table = table
      @unique_by = unique_by
      @debug = debug
    end

    def save(rows)
      rows.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if debug
      ScraperWiki.sqliteexecute('DROP TABLE %s' % table) rescue nil
      ScraperWiki.save_sqlite(unique_by, rows)
      # TODO: save run data (start / end / rowcount)
    end

    private

    attr_reader :table, :unique_by, :debug
  end

  # A series of classes for standardised approaches
  #   - list page + individual members
  #   - all on one page, with fragments, etc
  # We can ship some basics, and expect many to be subclassed
  class Scraper
    class MemberList
      def initialize(list_url:, list_class:, member_class:, defaults: {})
        @list_url = list_url
        @list_class = list_class
        @member_class = member_class
        @defaults = defaults
      end

      def data
        # TODO: default approach should be a `members` method, not `member_urls`
        # then we merge them together based on the `source` field
        ScrapedPage.new(list_url => list_class).scraped.member_urls.map do |member_url|
          defaults.merge(ScrapedPage.new(member_url => member_class).data)
        end
      end

      private

      attr_reader :list_url, :list_class, :member_class, :defaults
    end
  end
end


EveryPolitician::ScraperRun.new(unique_by: %i[id term], debug: ENV['MORPH_DEBUG']).save(
  EveryPolitician::Scraper::MemberList.new(
    list_url: 'http://www.chemiparlamenti.ge/en/parliamentarians',
    list_class: MembersPage,
    member_class: MemberPage,
    defaults: { term: 9 },
  ).data
)
