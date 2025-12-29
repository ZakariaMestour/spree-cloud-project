#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Wait for Database
echo "Waiting for Database to become available..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
echo "Database is up."

# Install JavaScript dependencies (Critical for styles)
echo "Checking JavaScript dependencies..."
yarn install

# Build the Tailwind CSS (This fixes the MissingAssetError)
echo "Building Tailwind CSS..."
bin/rails tailwindcss:build

# Prepare Database
echo "Preparing database..."
bin/rails db:prepare

# Check if admin user exists (Fixed: Use Spree::User instead of User)
if bin/rails runner "exit Spree::User.exists?(email: 'admin@spree.com') ? 0 : 1"; then
    echo "Existing data found. Skipping seeding."
else
    echo "No admin user found. Seeding database..."
    bin/rails db:seed
    bin/rails spree_sample:load
    echo "Seeding finished!"
fi

# Explicitly start the server
echo "Starting Spree Server..."
exec rails server -b 0.0.0.0