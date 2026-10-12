class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :admin_id
      t.integer :status

      t.timestamps
    end
    add_foreign_key :conversations, :users, column: :admin_id
  end
end
