# require "test_helper"

# class TwinOptionTest < TwinTest
#   class Song < Disposable::Twin
#     property :id # DISCUSS: needed for #save.
#     property :title

#     option :preview?
#     option :highlight?
#   end

#   let (:song) { Model::Song.new(1, "Broken") }
#   let (:twin) { Song.new(song, :preview? => false) }


#   # properties are read from model.
#   it { twin.id.must_equal 1 }
#   it { twin.title.must_equal "Broken" }

#   # option is not delegated to model.
#   it { twin.preview?.must_equal false }
#   # not passing option means zero.
#   it { twin.highlight?.must_equal nil }

#   # passing both options.
#   it { Song.new(song, preview?: true, highlight?: false).preview?.must_equal true }
# end
