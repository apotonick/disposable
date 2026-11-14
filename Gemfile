source "https://rubygems.org"
gemspec
gem "minitest-line"
gem "trailblazer-core-utils"

if ENV['DRY_TYPES']
  gem "dry-types", ENV['DRY_TYPES']
end

if ENV['ACTIVERECORD']
  gem "activerecord", "~> #{ENV['ACTIVERECORD']}.0"
end

gem "sqlite3", "~> 2.1"

# gem "declarative-builder"
