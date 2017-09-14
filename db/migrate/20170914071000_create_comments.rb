class CreateComments < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.text :message
      t.string :nickname
      t.references :user, foreign_key: true
      t.references :game, foreign_key: true, index: true

      t.timestamps
    end
  end
end
