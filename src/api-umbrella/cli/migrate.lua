local read_config = require "api-umbrella.cli.read_config"
local config = read_config()

if config["app_env"] == "development" then
  config["postgresql"]["username"] = "api-umbrella"
  config["postgresql"]["password"] = nil
end

local migrations = require("lapis.db.migrations")
local path = require "pl.path"

return function()
  -- FIXME: Don't drop the database on every migrate... Obviously. Just for
  -- testing/development purposes now.
  if config["app_env"] == "development" then
    os.execute([[psql -p 14006 -U api-umbrella postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'api_umbrella'"]])
    os.execute("psql -p 14006 -U api-umbrella postgres -c 'DROP DATABASE IF EXISTS api_umbrella'")
    os.execute("psql -p 14006 -U api-umbrella postgres -c 'CREATE DATABASE api_umbrella'")
    os.execute("psql -p 14006 -U api-umbrella api_umbrella -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto'")
  end
  migrations.create_migrations_table()
  migrations.run_migrations(require("migrations"))
  if config["app_env"] == "development" then
    os.execute("pg_dump -p 14006 -U api-umbrella --schema-only --no-owner api_umbrella > " .. path.join(os.getenv("API_UMBRELLA_SRC_ROOT"), "db/schema.sql"))
  end
end
