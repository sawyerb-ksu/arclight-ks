class IndexUsersUpdatedAt < ActiveRecord::Migration[7.1]
  def change
    add_index :users, [:updated_at, :guest]
  end
end
