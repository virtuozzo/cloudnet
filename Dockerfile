FROM atlashealth/ruby:2.2.0

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

ENTRYPOINT ["bundle", "exec"]
