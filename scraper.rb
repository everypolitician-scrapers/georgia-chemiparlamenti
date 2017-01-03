#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('li.member a/@href').map(&:text).uniq.each do |link|
    scrape_member URI.join(url, link)
  end
end

def scrape_member(url)
  noko = noko_for(url)

  box = noko.css('div#representative')
  links = box.xpath('.//td[contains(.,"Links")]/following-sibling::td')
  contacts = box.xpath('.//td[contains(.,"Contact Address")]/following-sibling::td').text.lines.map(&:tidy).reject(&:empty?)
  phone = contacts.shift.to_s.sub(/^- /, '')
  address = contacts.pop
  email = contacts.first.to_s.sub(/^- /, '')

  data = {
    id:        url.to_s[/representative\/(\d+)/, 1],
    name:      box.css('div#name').text.tidy,
    image:     box.css('div#photo img/@src').text,
    district:  box.xpath('.//td[contains(.,"Electoral District")]/following-sibling::td').text,
    elected:   box.xpath('.//td[contains(.,"Elected Date")]/following-sibling::td').text,
    party:     box.xpath('.//td[contains(.,"Faction")]/following-sibling::td').text,
    website:   links.css('a[href*="parliament.ge"]/@href').text,
    wikipedia: links.css('a[href*="wikipedia.org"]/@href').text,
    facebook:  links.css('a[href*="facebook.com"]/@href').text,
    twitter:   links.css('a[href*="twitter.com"]/@href').text,
    phone:     phone,
    email:     email,
    term:      8,
    source:    url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite(%i(id term), data)
end

scrape_list('http://www.chemiparlamenti.ge/en/who/unit/parliament/')
