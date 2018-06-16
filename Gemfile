source "https://rubygems.org"
gemspec

# gem "representable", path: "../representable"
# gem "representable", "3.0.0"
# gem "representable", github: "apotonick/representable"
# gem "declarative", path: "../declarative"
# gem "declarative", github: "apotonick/declarative"
gem "minitest-line"

{ "dry-types" => ENV['DRY_TYPES'], "activerecord" => ENV['ACTIVERECORD']}.each do |gem_name, dependency|
  next if dependency.nil?
  gem gem_name, dependency
end

# gem "dry-struct"


# gem "uber", path: "../uber"
# gem "declarative-option", path: "../declarative-option"
# gem "declarative-builder", path: "../declarative-builder"
# gem "representable", path: "../representable"
