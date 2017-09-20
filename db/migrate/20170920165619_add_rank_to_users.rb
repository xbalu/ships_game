class AddRankToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :rank, :integer, default: 1000
  end
end
