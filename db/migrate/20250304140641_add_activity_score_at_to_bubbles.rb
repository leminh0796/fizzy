class AddActivityScoreAtToBubbles < ActiveRecord::Migration[8.1]
  def change
    change_table :bubbles do |t|
      t.datetime :activity_score_at
      t.float :activity_score_order, null: false, default: 0
      t.change :activity_score, :float, null: false, default: 0

      t.index :activity_score_order, order: :desc
    end
  end
end
