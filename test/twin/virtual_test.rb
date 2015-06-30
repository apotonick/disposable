require 'test_helper'

class VirtualTest < MiniTest::Spec
  class CreditCardTwin < Disposable::Twin
    include Sync
    property :credit_card_number, virtual: true # no read, no write, it's virtual.
  end

  let (:twin) { CreditCardTwin.new(Object.new) }

  it {
    twin.credit_card_number = "123"

    twin.credit_card_number.must_equal "123"  # this is still readable in the UI.

    twin.sync

    hash = {}
    twin.sync do |nested|
      hash = nested
    end

    hash.must_equal("credit_card_number"=> "123")
  }
end