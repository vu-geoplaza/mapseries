FROM ruby:2.7-buster

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    #for troubleshooting
    && apt-get install -y nano \
    && apt-get install -y htop \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile* ./
ENV ENV_RAILS=production
RUN bundle install
COPY . .
RUN chmod +x /usr/src/app/lib/docker-entrypoint.sh && bundle exec rake app:update:bin
ENTRYPOINT ["/usr/src/app/lib/docker-entrypoint.sh"]
CMD sh -c "bin/rails server -e production -b 0.0.0.0"

EXPOSE 3000

