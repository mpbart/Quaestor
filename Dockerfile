FROM ruby:3.2.2-bookworm

CMD ["run_app"]

ENTRYPOINT ["bin/entrypoint.sh"]

RUN sh -c 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -'
RUN sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update && apt-get install -y postgresql-14 postgresql-client-14

RUN mkdir /code
WORKDIR /code

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 20 --retry 3

COPY . ./
