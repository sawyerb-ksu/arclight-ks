import the xml files under project create my-ead/atom-export-ead/ ****.xml's

to Set correct permissions on solr directory:
sudo chown -R 8983:8983 ../solr/arclight/data
sudo chmod -R 755 ../solr/arclight/data

building app
docker compose build --no cache

to start containers
docker-compose up -d

to prepare db and load tables
docker-compose exec app bundle exec rails db:prepare
docker-compose exec app bundle exec rails db:migrate
docker compose exec app bundle exec rails db:schema:load

-> to index in to solr
docker-compose exec app rake dul_arclight:index_dir DIR=/opt/app-root/finding-aid-data

now app is running on localhost:3000








<!-- # DUL ArcLight (Duke University Libraries)

Discovery & access application for archival material at Duke University Libraries. A front-end for archival finding aids / collection guides, built on the [ArcLight](https://github.com/projectblacklight/arclight) engine.

The application currently runs at [https://archives.lib.duke.edu](https://archives.lib.duke.edu).

## Requirements

* [Ruby](https://www.ruby-lang.org/en/) 2.7 or later
* [Rails](http://rubyonrails.org) 6.1 or later

## Getting Started

Please consult the **[DUL-ArcLight wiki](https://gitlab.oit.duke.edu/dul-its/dul-arclight/-/wikis/home)**
for full documentation. Here are a few common commands ...

You can index a set of sample Duke EAD files into Solr (takes a couple minutes):

    $ .docker/dev.sh exec app bundle exec rake dul_arclight:reindex_everything

Background processing jobs for indexing may be monitored using at:
http://localhost:3000/queues

To index a single finding aid:

    $ .docker/dev.sh exec app \
		bundle exec rake dul_arclight:index \
		FILE=./sample-ead/ead/rubenstein/rushbenjaminandjulia.xml \
		REPOSITORY_ID=rubenstein

Clear the current index:

	$ .docker/dev.sh exec app bundle exec rake arclight:destroy_index_docs

## OKD Notes

After the Helm chart is initially deployed, the Solr configuration must be manually
copied:

    $ oc rsync solr/arclight/conf/ solr-0:/var/solr/data/arclight/conf/

The web UI can then be used to scale down the Solr pods to 0 and back to 1.

The index can be populated by:

    $ oc exec POD -c app -- ./bin/rails dul_arclight:reindex_everything

Get the pod name with `oc get pods` or use the oc bash completion (if installed)
with prefix `app-`.

## Resources

* [ArcLight on GitHub](https://github.com/projectblacklight/arclight)
* [ArcLight project wiki](https://wiki.lyrasis.org/display/samvera/ArcLight) -->
