# frozen_string_literal: true

require 'test_helper'
require 'disposable/expose'
require 'disposable/composition'

# Disposable::Expose.
class ExposeTest < MiniTest::Spec
  module Model
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id
      property :title, from: :name
    end
  end

  class AlbumExpose < Disposable::Expose
    from Twin::Album.definitions.values
  end

  let(:album) { Model::Album.new(1, 'Dick Sandwich') }
  subject { AlbumExpose.new(album) }

  describe 'readers' do
    it do
      _(subject.id).must_equal 1
      _(subject.title).must_equal 'Dick Sandwich'
    end
  end

  describe 'writers' do
    it do
      subject.id = 3
      subject.title = 'Eclipse'

      _(subject.id).must_equal 3
      _(subject.title).must_equal 'Eclipse'
      _(album.id).must_equal 3
      _(album.name).must_equal 'Eclipse'
    end
  end
end

# Disposable::Composition.
class ExposeCompositionTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id)
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id,                 on: :album
      property :name,               on: :album
      property :band_id, from: :id, on: :band
    end

    class AlbumComposition < Disposable::Composition
      from Twin::Album.definitions.values
    end
  end

  let(:band) { Model::Band.new(1) }
  let(:album) { Model::Album.new(2, 'Dick Sandwich') }
  subject { Twin::AlbumComposition.new(album: album, band: band) }

  describe 'readers' do
    it { _(subject.id).must_equal 2 }
    it { _(subject.band_id).must_equal 1 }
    it { _(subject.name).must_equal 'Dick Sandwich' }
  end

  describe 'writers' do
    it do
      subject.id = 3
      subject.band_id = 4
      subject.name = 'Eclipse'

      _(subject.id).must_equal 3
      _(subject.band_id).must_equal 4
      _(subject.name).must_equal 'Eclipse'
      _(band.id).must_equal 4
      _(album.id).must_equal 3
      _(album.name).must_equal 'Eclipse'
    end
  end
end
