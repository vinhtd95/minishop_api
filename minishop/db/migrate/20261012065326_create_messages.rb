class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :sender_id
      t.text :body

      t.timestamps
    end
    add_foreign_key :messages, :users, column: :sender_id
  end
end
