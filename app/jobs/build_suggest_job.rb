# frozen_string_literal: true

require 'uri'
require 'net/http'
#
# Rebuild the Solr suggester index
# https://lucene.apache.org/solr/guide/8_0/suggester.html
#
class BuildSuggestJob < ApplicationJob
  queue_as :index

  def perform
    commit_and_expunge_deletes
    build_suggest
  end

  def commit_and_expunge_deletes
    response = Net::HTTP.start(solr_uri.host, solr_uri.port) do |http|
      http.read_timeout = 600 # 10m
      http.post("#{solr_uri.path}/update", '<commit expungeDeletes="true"/>', { 'content-type' => 'text/xml' })
    end

    response.value
  end

  def build_suggest
    query = URI.encode_www_form({ 'suggest' => 'true',
                                  'suggest.build' => 'true',
                                  'suggest.dictionary' => 'mySuggester' })

    response = Net::HTTP.start(solr_uri.host, solr_uri.port) do |http|
      http.read_timeout = 600 # 10m
      http.get("#{solr_uri.path}/suggest?#{query}", { 'accept' => 'application/json' })
    end

    response.value
  end

  def solr_uri
    @solr_uri ||= URI(ENV.fetch('SOLR_URL'))
  end
end
