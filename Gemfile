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

activerecord_version = ENV.fetch('ACTIVERECORD', '5.2').to_f
if activerecord_version.to_f >= 8
  gem "sqlite3", "~> 2.1"
elsif activerecord_version.to_f >= 6
  gem "sqlite3", "~> 1.4"
else
  gem "sqlite3", "~> 1.3.0"
end

# gem "declarative-builder"
