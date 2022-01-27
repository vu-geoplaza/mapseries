FROM ruby:2.7-buster

ARG APP_USER=appuser
ARG APP_GROUP=appgroup
ARG APP_USER_UID=1000
ARG APP_GROUP_GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    #for troubleshooting
    && apt-get install -y nano \
    && apt-get install -y htop \
    && addgroup --gid $APP_GROUP_GID $APP_GROUP \
    && adduser --system --disabled-login --uid $APP_USER_UID --ingroup $APP_GROUP $APP_USER \
    && mkdir /usr/src/app \
    && chown $APP_USER:$APP_GROUP /usr/src/app \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY --chown=$APP_USER:$APP_GROUP Gemfile* ./
ENV ENV_RAILS=production
RUN bundle install
COPY --chown=$APP_USER:$APP_GROUP . .
RUN chmod +x /usr/src/app/lib/docker-entrypoint.sh && bundle exec rake app:update:bin
ENTRYPOINT ["/usr/src/app/lib/docker-entrypoint.sh"]
CMD sh -c "bin/rails server -e production -b 0.0.0.0"

EXPOSE 3000

