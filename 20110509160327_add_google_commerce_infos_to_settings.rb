class AddGoogleCommerceInfosToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :google_account, :string
    add_column :settings, :google_affiliation_store_name, :string
  end

  def self.down
    remove_column :settings, :google_account
    remove_column :settings, :google_affiliation_store_name
  end
end
