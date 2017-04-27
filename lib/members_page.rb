# frozen_string_literal: true

require 'scraped'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.xpath('//a[@data-mp-id]/@href').map(&:text).uniq
  end
end
