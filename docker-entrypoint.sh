#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Wait for Database
echo "Waiting for Database host 'db'..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
echo "Database is up."

# Migrate Database (Fast)
echo "Checking database..."
bin/rails db:prepare

# Check if admin user exists
if bin/rails runner "exit Spree::User.exists?(email: 'admin@spree.com') ? 0 : 1"; then
    echo "Skipping seeding (Data exists)."
else
    echo "Seeding database..."
    bin/rails db:seed
    bin/rails spree_sample:load
    echo "Seeding finished!"
fi

# Start Server
echo "Starting Spree Server..."
exec "$@"