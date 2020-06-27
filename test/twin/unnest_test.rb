# frozen_string_literal: true

require 'test_helper'

class UnnestTest < MiniTest::Spec
  class Twin < Disposable::Twin
    property :content do
      property :id, nice: 'yes'
      collection :ids, status: 'healthy'

      property :email do
      end
    end

    unnest :id,    from: :content
    unnest :ids,   from: :content
    unnest :email, from: :content
  end

  it 'copies property option' do
    _(Twin.definitions.get(:id).extend(Declarative::Inspect).inspect).must_equal %(#<Disposable::Twin::Definition: @options={:nice=>\"yes\", :private_name=>:id, :name=>\"id\", :readable=>false, :writeable=>false}>)
    _(Twin.definitions.get(:ids).extend(Declarative::Inspect).inspect).must_equal %(#<Disposable::Twin::Definition: @options={:status=>\"healthy\", :collection=>true, :private_name=>:ids, :name=>\"ids\", :readable=>false, :writeable=>false}>)
    # also copies :nested.
    _(Twin.definitions.get(:email).extend(Declarative::Inspect).inspect).must_equal %(#<Disposable::Twin::Definition: @options={:private_name=>:email, :nested=>#<Class:>, :name=>\"email\", :readable=>false, :writeable=>false}>)
  end

  it 'exposes accessors on top-level twin' do
    twin = Twin.new(OpenStruct.new(content: OpenStruct.new))

    _(twin.email).must_be_nil
    twin.email = 2
    _(twin.email.model).must_equal 2

    _(twin.id).must_be_nil
    twin.id = 1
    _(twin.id).must_equal 1
  end
end
