require "test_helper"
require "disposable/twin/coercion"
require "disposable/twin/property/struct"

class StructCoercionTest < Minitest::Spec
  ExpenseModel = Struct.new(:content)

  class Expense < Disposable::Twin
    feature Property::Struct
    feature Coercion

    property :content do
      property :amount, type: Types::Form::Float
    end

    unnest :amount, from: :content
  end


  it do
    twin = Expense.new( ExpenseModel.new({}) )

    #- direct access, without unnest
    twin.content.amount.must_be_nil
    twin.content.amount = "1.8"
    twin.content.amount.must_equal 1.8
  end

  it "via unnest" do
    twin = Expense.new( ExpenseModel.new({}) )

    twin.amount.must_be_nil
    twin.amount = "1.8"
    twin.amount.must_equal 1.8
  end
end
