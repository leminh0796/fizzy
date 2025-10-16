class RemoveClosureReasons < ActiveRecord::Migration[8.1]
  def change
    drop_table :closure_reasons
  end
end
