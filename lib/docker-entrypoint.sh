#!/bin/sh
# https://stackoverflow.com/a/38732187/1935918
#set -e

if [ -f /usr/src/app/tmp/pids/server.pid ]; then
  rm /usr/src/app/tmp/pids/server.pid
fi

#bundle exec rake db:migrate
bundle exec rake sunspot:reindex

# Then exec the container's main process (what's set as CMD in the docker-compose.yml).
exec bundle exec "$@"