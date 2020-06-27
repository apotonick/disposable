# frozen_string_literal: true

require 'test_helper'

class WriteableTest < MiniTest::Spec
  Credentials = Struct.new(:password, :credit_card) do
    def password=(_v)
      raise "don't call me!"
    end
  end

  CreditCard = Struct.new(:name, :number) do
    def number=(_v)
      raise "don't call me!"
    end
  end

  class PasswordForm < Disposable::Twin
    feature Setup
    feature Sync

    property :password, writeable: false

    property :credit_card do
      property :name
      property :number, writeable: false
    end
  end

  let(:cred) { Credentials.new('secret', CreditCard.new('Jonny', '0987654321')) }

  let(:twin) { PasswordForm.new(cred) }

  it {
    _(twin.password).must_equal 'secret'
    _(twin.credit_card.name).must_equal 'Jonny'
    _(twin.credit_card.number).must_equal '0987654321'

    # manual setting on the twin works.
    twin.password = '123'
    _(twin.password).must_equal '123'

    twin.credit_card.number = '456'
    _(twin.credit_card.number).must_equal '456'

    twin.sync

    _(cred.inspect).must_equal '#<struct WriteableTest::Credentials password="secret", credit_card=#<struct WriteableTest::CreditCard name="Jonny", number="0987654321">>'

    # test sync{}.
    hash = {}
    twin.sync do |nested|
      hash = nested
    end

    _(hash).must_equal('password' => '123', 'credit_card' => { 'name' => 'Jonny', 'number' => '456' })
  }
end
