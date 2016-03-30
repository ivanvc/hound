FROM ruby:2.2.2
MAINTAINER Ivan Valdes <ivan@vald.es>

# Hound
RUN apt-get update && apt-get install -y --no-install-recommends \
    # For assets compilation
    nodejs \
    # Capybara-webkit deps
    dbus-1-dbg \
    libqt5webkit5-dev \
    qt5-default \
    xvfb \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && dbus-uuidgen > /etc/machine-id

RUN gpg --keyserver pool.sks-keyservers.net --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D 114F43EE0176B71C7BC219DD50A3051F888C628D

ENV NODE_VERSION 0.10.40
ENV NPM_VERSION 2.11.3

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
	&& curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --verify SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
	&& tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install
COPY package.json /usr/src/app/
RUN npm install

COPY . /usr/src/app
RUN mv /usr/src/app/.env.local /usr/src/app/.env

CMD /usr/src/app/bin/setup
