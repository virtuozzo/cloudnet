FROM atlashealth/ruby:2.2.1

RUN apt-get update \
  && apt-get install -y \
    curl \
    git-core \
    libssl-dev \
    libpq-dev \
    nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

WORKDIR /app
ADD . /app

RUN bundle install --without development test

# Using the 'test' env is a little hack to avoid symmetric_encryption complaining about bad
# a RSA config key. Usually we'd just compile assets with a full env, but we can't do that
# during docker build.
RUN RAILS_ENV=test bundle exec rake assets:precompile

ENTRYPOINT ["bundle", "exec"]
