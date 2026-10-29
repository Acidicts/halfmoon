# frozen_string_literal: true

class AddOAuthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string unless column_exists?(:users, :provider)
    add_column :users, :uid, :string unless column_exists?(:users, :uid)
    add_column :users, :email, :string unless column_exists?(:users, :email)
    add_column :users, :slack_id, :string unless column_exists?(:users, :slack_id)

    add_index :users, %i[provider uid], unique: true unless index_exists?(:users, %i[provider uid])
  end
end
