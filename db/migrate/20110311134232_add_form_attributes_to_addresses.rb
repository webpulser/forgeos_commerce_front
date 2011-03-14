class AddFormAttributesToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :form_attributes, :text
  end

  def self.down
    remove_column :addresses, :form_attributes
  end
end