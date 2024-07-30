FROM ruby:3.2-bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && apt-get install -y proj-bin libproj-dev \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    #for troubleshooting
    && adduser -disabled-password appuser \
    && mkdir /usr/src/app \
    && chown appuser /usr/src/app \
    && rm -rf /var/lib/apt/lists/*

USER appuser
WORKDIR /usr/src/app
COPY --chown=appuser Gemfile* ./
ENV ENV_RAILS=production
RUN bundle install
COPY --chown=appuser . .
RUN chmod -R 777 /usr/src/app/tmp && chmod +x /usr/src/app/lib/docker-entrypoint.sh && bundle exec rake app:update:bin
ENTRYPOINT ["sh","/usr/src/app/lib/docker-entrypoint.sh"]
CMD sh -c "bin/rails server -e production -b 0.0.0.0"

EXPOSE 3000

