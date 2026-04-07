# frozen_string_literal: true

# db/migrate/20260407100000_create_users.rb

class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
