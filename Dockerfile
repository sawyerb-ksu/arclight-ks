ARG ruby_version="3.4.1"
ARG builder="builder"
ARG bundle="bundle"

FROM ruby:${ruby_version} AS builder

SHELL ["/bin/bash", "-c"]

ENV APP_ROOT="/opt/app-root" \
    APP_USER="app-user" \
    APP_UID="1001" \
    APP_GID="0" \
    BUNDLE_USER_HOME="${GEM_HOME}" \
    FINDING_AID_DATA="/data" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    RAILS_ENV="development" \
    TZ="US/Eastern"

RUN set -eux; \
    apt-get -y update; \
    apt-get -y install git jq libmemcached-tools libpq-dev locales nodejs npm rsync wait-for-it; \
    rm -rf /var/lib/apt/lists/*; \
    echo "$LANG UTF-8" >> /etc/locale.gen; \
    locale-gen $LANG; \
    npm install -g yarn; \
    gem update --system; \
    useradd -u $APP_UID -g $APP_GID -d $APP_ROOT -s /sbin/nologin $APP_USER

WORKDIR $APP_ROOT

#-------------------------+

FROM ${builder} AS bundle

COPY .ruby-version Gemfile Gemfile.lock ./

RUN gem install bundler -v "$(tail -1 Gemfile.lock | awk '{print $1}')" && \
    bundle install && \
    chmod -R g=u $GEM_HOME

#-------------------------+

FROM ${bundle} AS app

ARG build_date="1970-01-01T00:00:00Z"
ARG git_commit="0"

LABEL org.opencontainers.image.description="K-STATE University Libraries archives and manuscripts discovery UI"
LABEL org.opencontainers.image.title="KSUL Archives & Manuscripts Collection Guides"
LABEL org.opencontainers.image.url="https://archives.lib.duke.edu"
# LABEL org.opencontainers.image.url="https://dev-atom.ksulib.net/repository/browse"
LABEL org.opencontainers.image.source="https://gitlab.oit.duke.edu/dul-its/dul-arclight"
LABEL org.opencontainers.image.documentation="https://gitlab.oit.duke.edu/dul-its/dul-arclight"
LABEL org.opencontainers.image.vendor="Kansas State University Libraries"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.created="${build_date}"
LABEL org.opencontainers.image.revision="${git_commit}"
LABEL org.opencontainers.image.authors="Kansas State University Libraries"

COPY . .

# RUN mkdir -p $APP_ROOT/tmp/cache && \
#     mkdir -p $APP_ROOT/tmp/pids && \
#     mkdir -p $APP_ROOT/tmp/sockets && \
#     chown -R $APP_UID:$APP_GID $APP_ROOT/tmp && \
#     chmod -R 775 $APP_ROOT/tmp

RUN SECRET_KEY_BASE=$(./bin/rails secret) ./bin/rails assets:precompile && \
    mkdir -p $FINDING_AID_DATA && \
    git config --system --add safe.directory $FINDING_AID_DATA && \
    chmod -R g=u . $FINDING_AID_DATA

VOLUME $FINDING_AID_DATA

#-------- newly added
# COPY . .
#-------- newly added

USER $APP_USER

EXPOSE 3000

CMD ["./bin/rails", "server"]
