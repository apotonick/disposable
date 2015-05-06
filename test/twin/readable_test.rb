require 'test_helper'

class ReadableTest < MiniTest::Spec
  Credentials = Struct.new(:password) do
    def password
      raise "don't call me!"
    end
  end

  class PasswordForm < Disposable::Twin
    include Setup

    property :password, readable: false
  end

  let (:cred) { Credentials.new("secret") }
  let (:twin) { PasswordForm.new(cred) }

  it {
    twin.password.must_equal nil
    # manual setting on the twin works.
    twin.password = "123"
    twin.password.must_equal "123"

    # TODO: test nested hash.
    # twin.sync
    # cred.password.must_equal "123"



    # hash = {}
    # twin.save do |nested|
    #   hash = nested
    # end

    # hash.must_equal("password"=> "123")
  }
end