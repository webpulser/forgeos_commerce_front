class AddCompanyToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :company, :string
    add_column :people, :newsletter, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :people, :company
    remove_column :people, :newsletter
  end
end