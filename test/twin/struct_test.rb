# require 'test_helper'
# require "representable/debug"

# require 'disposable/twin/struct'



# module Representable
#   # The generic representer. Brings #to_hash and #from_hash to your object.
#   # If you plan to write your own representer for a new media type, try to use this module (e.g., check how JSON reuses Hash's internal
#   # architecture).
#   module Object
#     def self.included(base)
#       base.class_eval do
#         include Representable
#         extend ClassMethods
#         register_feature Representable::Object
#       end
#     end


#     module ClassMethods
#       def collection_representer_class
#         Collection
#       end
#     end

#     def from_object(data, options={}, binding_builder=Binding)
#       update_properties_from(data, options, binding_builder)
#     end

#     # FIXME: remove me! only here to avoid AllowSymbols from Twin:Representer
#     def update_properties_from(doc, options, format)
#       representable_mapper(format, options).deserialize(doc, options)
#     end
#   end
# end





# class TwinStructTest < MiniTest::Spec
#   class Song < Disposable::Twin
#     include Struct
#     property :number, default: 1 # FIXME: this should be :default_if_nil so it becomes clear with a model.
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


#   describe "writing" do
#     let (:song) { Song.new(model, {cool?: true}) }
#     let (:model) { {number: 3} }

#     # writer
#     it do
#       song.number = 9
#       song.number.must_equal 9
#       model[:number].must_equal 3
#     end

#     # writer with sync
#     it do
#       song.number = 9
#       song.sync

#       song.number.must_equal 9
#       model["number"].must_equal 9

#       song.send(:model).object_id.must_equal model.object_id
#     end
#   end

# end


# # Non-lazy initialization. This will copy all properties from the wrapped object to the twin when
# # instantiating the twin.


# class TwinWithNestedStructTest < MiniTest::Spec
#   class Song < Disposable::Twin
#     include Setup
#     property :title

#     property :options, twin: true do # don't call #to_hash, this is triggered in the twin's constructor.
#       include Struct
#       property :recorded
#       property :released

#       property :preferences, twin: true do
#         include Struct
#         property :show_image
#         property :play_teaser
#       end
#     end
#   end

#   # FIXME: test with missing hash properties, e.g. without released and with released:false.
#   let (:model) { OpenStruct.new(title: "Seed of Fear and Anger", options: {recorded: true, released: 1,
#     preferences: {show_image: true, play_teaser: 2}}) }

#   # public "hash" reader
#   it { Song.new(model).options.recorded.must_equal true }

#   # public "hash" writer
#   it ("xxx") {
#     song = Song.new(model)

#     puts song.inspect

#     # puts song.options.inspect
#     # puts song.options.preferences.to_hash
#     # raise

#     song.options.recorded = "yo"
#     song.options.recorded.must_equal "yo"

#     song.options.preferences.show_image.must_equal true
#     song.options.preferences.play_teaser.must_equal 2

#     song.options.preferences.show_image= 9


#     # song.extend(Disposable::Twin::Struct::Sync)
#     song.sync # this is only called on the top model, e.g. in Reform#save.

#     model.title.must_equal "Seed of Fear and Anger"
#     model.options["recorded"].must_equal "yo"
#     model.options["preferences"].must_equal({"show_image" => 9, "play_teaser"=>2})
#   }
# end



# class SyncRepresenter < Representable::Decorator
#   include Representable::Object

#   property :title
#   property :album, instance: lambda { |fragment, *| fragment } do
#     property :name
#   end
# end

# album = Struct.new(:name).new("Ass It Is")

# SyncRepresenter.new(obj = Struct.new(:title, :album).new).from_object(Struct.new(:title, :album).new("Eternal Scream", album))

# puts obj.title.inspect
# puts obj.inspect
# # reform
# #   sync: twin.title = "Good Bye"
# #         album.sync (copy attributes in nested form)
# #           twin.name = "Matters"
# #   save: twin.save (this will do twin.sync... does that call save on all nested twins, too, or do we still have to do that in reform?)