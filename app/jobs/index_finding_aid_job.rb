# frozen_string_literal: true

require 'English'
require 'dul_arclight/index_error'

# Index a finding aid into Solr using data mappings configured via traject
class IndexFindingAidJob < ApplicationJob
  queue_as :index

  def perform(path, repo_id)
    env = { 'REPOSITORY_ID' => repo_id }

    # Calling the traject command directly here instead of
    # the dul_arclight:index rake task because the latter
    # doesn't return the exit code for the traject command.

    cmd = %W[ bundle exec traject
              -u #{ENV.fetch('SOLR_URL', nil)}
              -i xml
              -c ./lib/traject/dul_ead2_config.rb
              #{path} ]

    output = IO.popen(env, cmd, chdir: Rails.root, err: %i[child out], &:read)

    raise DulArclight::IndexError, output unless $CHILD_STATUS.success?

    Rails.logger.debug output
  end
end
