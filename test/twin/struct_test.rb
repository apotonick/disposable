# require "test_helper"
# require 'disposable/twin/struct'

# class TwinStructTest < MiniTest::Spec
#   class Song < Disposable::Twin
#     include Struct
#     property :number, :default => 1 # FIXME: this should be :default_if_nil so it becomes clear with a model.
#     option   :cool?
#   end

#   # empty hash
#   it { Song.new({}).number.must_equal 1 }
#   # model hash
#   it { Song.new(number: 2).number.must_equal 2 }

#   # with hash and options as one hash.
#   it { Song.new(number: 3, cool?: true).cool?.must_equal true }
#   it { Song.new(number: 3, cool?: true).number.must_equal 3 }

#   # with model hash and options hash separated.
#   it { Song.new({number: 3}, {cool?: true}).cool?.must_equal true }
#   it { Song.new({number: 3}, {cool?: true}).number.must_equal 3 }
# end