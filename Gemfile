source "https://rubygems.org"
gemspec
gem "minitest-line"

{ "dry-types" => ENV['DRY_TYPES'], "activerecord" => ENV['ACTIVERECORD']}.each do |gem_name, dependency|
  next if dependency.nil?
  gem gem_name, dependency
end


