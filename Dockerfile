FROM hackedunit/baseimage-ruby

RUN apt-get update \
  && apt-get install -y \
    libssl-dev \
    libpq-dev \
    nodejs \
    g++ \
    gcc \
    make \
    cron \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

WORKDIR /app

ADD Gemfile /app
ADD Gemfile.lock /app

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install bundler
RUN bundle install --without development test

ADD . /app

# A bit of a hack to get assets to compile without the usual env vars. There doesn't seem
# to be a way to disable the symmetric-encryption gem, so we just give it an arbitrary key.
RUN SYMMETRIC_ENCRYPTION_KEY=ZkfIjDCGLwG6fcC3yaOyZDxL6wokGRikvUsbdRj+WZOGhhBoIaCkN84ZDYrMp3OczwCABzR5vt/y8v9KdjsjARrkitBKfkCB8/nLbfsHDVHSyOsZAu9vOvkqG08KoT4xaBulE4s2fyb3t7QmKmNJ7g3Z/vg87Wuk10/Y27VDrzeW/BOl9ADEQ0CC526zdDZqzWOb479Pc9rK6Rs0+tQukJy39uHI7TJdXp+Z0JuvOwiMWgd2Du5TeHn62gbbmIuBC8aL/96uDkbVPsL6Aq2M2MrxzcMJ5XF6gLM/nEIIL/6zN+tRmC5HO4WHaMOAV1pvaYQywV1P+Ti2GkmspckX4w== \
  bundle exec rake assets:precompile

ENTRYPOINT ["bundle", "exec"]
