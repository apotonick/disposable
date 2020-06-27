# frozen_string_literal: true

require 'test_helper'

class BuilderTest < MiniTest::Spec
  module Model
    Song = Struct.new(:id, :title)
    Hit = Struct.new(:id, :title)
    Evergreen = Struct.new(:id, :title)
  end

  class Twin < Disposable::Twin
    property :id
    property :title
    # option   :is_released

    include Builder
    builds lambda { |model, options|
      return Hit       if model.is_a? Model::Hit
      return Evergreen if options[:evergreen]
    }
  end

  class Hit < Twin
  end

  class Evergreen < Twin
  end

  it { _(Twin.build(Model::Song.new)).must_be_instance_of Twin }
  it { _(Twin.build(Model::Hit.new)).must_be_instance_of  Hit }
  it { _(Twin.build(Model::Evergreen.new, evergreen: true)).must_be_instance_of Evergreen }
end
