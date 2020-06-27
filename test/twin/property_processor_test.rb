# frozen_string_literal: true

require 'test_helper'

class PropertyProcessorTest < Minitest::Spec
  Album  = Struct.new(:title, :artist, :songs)
  Artist = Struct.new(:name)
  Song   = Struct.new(:id)

  class AlbumTwin < Disposable::Twin
    property :title

    property :artist do
      property :name
    end

    collection :songs do
      property :id
    end
  end

  describe 'collection' do
    let(:twin) { AlbumTwin.new(Album.new('Live!', Artist.new, [Song.new(1), Song.new(2)])) }
    it 'yields twin, index' do
      called = []
      Disposable::Twin::PropertyProcessor.new(twin.class.definitions.get(:songs), twin).call { |v, i| called << [v.model, i] }

      _(called.inspect).must_equal %([[#<struct PropertyProcessorTest::Song id=1>, 0], [#<struct PropertyProcessorTest::Song id=2>, 1]])
    end

    it 'yields twin' do
      called = []
      Disposable::Twin::PropertyProcessor.new(twin.class.definitions.get(:songs), twin).call { |v| called << [v.model] }

      _(called.inspect).must_equal %([[#<struct PropertyProcessorTest::Song id=1>], [#<struct PropertyProcessorTest::Song id=2>]])
    end

    it 'allows nil collection' do
      twin = AlbumTwin.new(Album.new('Live!', Artist.new, nil))

      called = []
      Disposable::Twin::PropertyProcessor.new(twin.class.definitions.get(:songs), twin).call { |v, i| called << [v.model, i] }

      _(called.inspect).must_equal %([])
    end
  end
end
