require "disposable/twin"
require 'reform'
require 'ostruct'
require 'benchmark'

class BandForm < Reform::Form
  property :name, validates: {presence: true}

  collection :songs do
    property :title, validates: {presence: true}
  end
end

songs = 50.times.collect { OpenStruct.new(title: "Be Stag") }
band = OpenStruct.new(name: "Teenage Bottlerock", songs: songs)

songs_params = 50.times.collect { {title: "Commando"} }

time = Benchmark.measure do
  100.times.each do
    form = BandForm.new(band)
    form.validate("name" => "Ramones", "songs" => songs_params)
    form.save
  end
end

puts time

# with old Fields.new(to_hash)
#   4.200000
# 20%
# with setup and new(fields).from_object(twin) instead of Fields.new(to_hash)
#   3.680000   0.000000   3.680000 (  3.685796)