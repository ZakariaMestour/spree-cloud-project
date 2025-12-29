FROM ruby:3.4.7


# Install dependencies required by Spree and Rails
RUN apt-get update -qq && apt-get install -y \
    postgresql-client \
    build-essential \
    libvips \
    curl \
    git \
    libvips-dev

# Install Node.js and Yarn (Needed for Spree frontend assets)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global yarn

WORKDIR /app

# Install Gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the application code
COPY . .

# Setup the entrypoint script
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
