FROM ubuntu:xenial
MAINTAINER PotHix <pothix@pothix.com>

RUN apt-get update -qq && apt-get install -y --no-install-recommends apt-utils

# build dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends software-properties-common python-software-properties build-essential unzip git dh-autoreconf curl openjdk-9-jre

# using brightbox trusty packages. According to bringhtbox team, it works good with xenial
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN sed -i 's/xenial/trusty/g' /etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-xenial.list
RUN apt-get update -qq && apt-get install -y --no-install-recommends ruby2.2 ruby2.2-dev
RUN sed -i 's/deb http/#deb http/g' /etc/apt/sources.list.d/brightbox-ubuntu-ruby-ng-xenial.list

RUN apt-get update -qq && apt-get install -y --no-install-recommends libcurl3-dev libmysqlclient-dev postgresql-common libsqlite3-dev libmagickwand-dev imagemagick libpq-dev libsnappy-dev mongodb-clients

RUN git clone https://github.com/spotify/sparkey.git /tmp/sparkey
RUN cd /tmp/sparkey && autoreconf --install && ./configure && make && make install && ldconfig

RUN mkdir /intervac

ADD ./lib /intervac/lib

WORKDIR /intervac
VOLUME .:/intervac

# fixes Rmagick problem with Magick-config
RUN ln -s /usr/lib/x86_64-linux-gnu/ImageMagick-6.8.9/bin-Q16/Magick-config /usr/bin/Magick-config

RUN gem install bundler --no-ri --no-rdoc

ADD Gemfile /intervac/Gemfile
ADD Gemfile.lock /intervac/Gemfile.lock
RUN bundle install

RUN curl -O https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && chmod +x wait-for-it.sh

EXPOSE 3000

CMD ["wait-for-it.sh", "db:27017", "--", "bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0", "-P", "/tmp/rails.pid"]
