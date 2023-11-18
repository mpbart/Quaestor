FROM ruby:3.2.2-bookworm

CMD ["run_app"]

ENTRYPOINT ["bin/entrypoint.sh"]

RUN apt-get update && apt-get install -y postgresql-client

RUN mkdir /code
WORKDIR /code

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 20 --retry 3

COPY . ./
