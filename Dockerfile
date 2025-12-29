FROM ruby:3.3.0

# 1. Install System Dependencies
RUN apt-get update -qq && apt-get install -y \
    postgresql-client \
    build-essential \
    libvips \
    curl \
    git \
    libvips-dev

# 2. Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global yarn

WORKDIR /app

# 3. Install Gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# 4. Copy Code
COPY . .

# --- CRITICAL FIXES BELOW ---

# Fix permissions for Windows -> Linux transfers
RUN chmod +x bin/*

# Build Assets NOW (instead of at startup)
# This prevents the "CrashLoopBackOff" in Kubernetes
RUN yarn install
RUN SECRET_KEY_BASE=dummy_key_for_build bin/rails tailwindcss:build

# ----------------------------

# 5. Setup Entrypoint
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]