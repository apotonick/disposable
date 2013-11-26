require 'test_helper'

require 'active_record'
class Invoice < ActiveRecord::Base
  has_many :invoice_items
end

class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{Dir.pwd}/database.sqlite3"
)

# ActiveRecord::Schema.define do
#   create_table :invoices do |table|
#     table.timestamps
#   end
# end

# ActiveRecord::Schema.define do
#   create_table :invoice_items do |table|
#     table.column :invoice_id, :string
#     table.timestamps
#   end
# end

# TODO: test auto-loading of Rails assets.
require 'disposable/facade/active_record'

class ActiveRecordAssociationsTest < MiniTest::Spec
  class Item < Disposable::Facade
    facades InvoiceItem

    include Disposable::Facade::ActiveRecord
  end

  let (:invoice) { Invoice.new }
  it "allows adding facades to associations" do
    # tests #is_a?
    InvoiceItem.new.facade.class.must_equal Item
    InvoiceItem.new.facade.is_a?(InvoiceItem).must_equal true

    invoice.invoice_items << InvoiceItem.new.facade
  end
end