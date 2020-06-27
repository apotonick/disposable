# frozen_string_literal: true

require 'test_helper'

class ReadableTest < MiniTest::Spec
  Credentials = Struct.new(:password, :credit_card) do
    def password
      raise "don't call me!"
    end
  end

  CreditCard = Struct.new(:name, :number) do
    def number
      raise "don't call me!"
    end
  end

  class PasswordForm < Disposable::Twin
    feature Setup
    feature Sync

    property :password, readable: false

    property :credit_card do
      property :name
      property :number, readable: false
    end
  end

  let(:cred) { Credentials.new('secret', CreditCard.new('Jonny', '0987654321')) }

  let(:twin) { PasswordForm.new(cred) }

  it {
    _(twin.password).must_be_nil            # not readable.
    _(twin.credit_card.name).must_equal 'Jonny'
    _(twin.credit_card.number).must_be_nil  # not readable.

    # manual setting on the twin works.
    twin.password = '123'
    _(twin.password).must_equal '123'

    twin.credit_card.number = '456'
    _(twin.credit_card.number).must_equal '456'

    twin.sync

    # it writes, but does not read.
    _(cred.inspect).must_equal '#<struct ReadableTest::Credentials password="123", credit_card=#<struct ReadableTest::CreditCard name="Jonny", number="456">>'

    # test sync{}.
    hash = {}
    twin.sync do |nested|
      hash = nested
    end

    _(hash).must_equal('password' => '123', 'credit_card' => { 'name' => 'Jonny', 'number' => '456' })
  }

  # allow passing non-readable value as option.
  it do
    twin = PasswordForm.new(cred, password: 'open sesame!')
    _(twin.password).must_equal 'open sesame!'
  end
end
