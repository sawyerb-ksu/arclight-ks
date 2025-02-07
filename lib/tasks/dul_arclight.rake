# frozen_string_literal: true

require_relative '../../config/application'
require 'dul_arclight'
require 'benchmark'

# Read the repository configuration
repo_config = YAML.safe_load_file('./config/repositories.yml')

# rubocop:disable Metrics/BlockLength
namespace :dul_arclight do
  desc 'Index an EAD document, use FILE=<path/to/ead.xml> and REPOSITORY_ID=<myid>'
  # Based on the core index rake task but adjusted for DUL traject config, see:
  # https://github.com/projectblacklight/arclight/blob/main/lib/tasks/index.rake
  task index: :environment do
    raise 'Please specify your EAD document, ex. FILE=<path/to/ead.xml>' unless ENV['FILE']

    print "Loading #{ENV.fetch('FILE', nil)} into index...\n"
    solr_url = ENV.fetch('SOLR_URL', nil)
    elapsed_time = Benchmark.realtime do
      `bundle exec traject -u #{solr_url} -i xml -c ./lib/traject/dul_ead2_config.rb #{ENV.fetch('FILE', nil)}`
    end
    print "Indexed #{ENV.fetch('FILE', nil)} (in #{elapsed_time.round(3)} secs).\n"
  end

  desc 'Index a directory of EADs, use DIR=<path/to/directory> and REPOSITORY_ID=<myid>'
  # Based on the core index rake task but adjusted for DUL traject config, see:
  # https://github.com/projectblacklight/arclight/blob/main/lib/tasks/index.rake
  task index_dir: :environment do
    raise 'Please specify your directory, ex. DIR=<path/to/directory>' unless ENV['DIR']

    Dir.glob(File.join(ENV.fetch('DIR', nil), '*.xml')).each do |file|
      system("rake dul_arclight:index FILE=#{file}")
    end
  end

  desc 'Reindex all finding aids in the data directory via background jobs'
  task reindex_everything: :environment do
    puts "Looking in #{DulArclight.finding_aid_data} ..."

    # Find our configured repositories, get their IDs
    repo_config.each_key do |repo_id|
      puts repo_id

      Dir.glob(File.join(DulArclight.finding_aid_data, 'ead', repo_id, '*.xml')) do |path|
        puts path
        IndexFindingAidJob.perform_later(path, repo_id)
      end
    end

    puts 'All collections queued for re-indexing.'
  end
end
# rubocop:enable Metrics/BlockLength
