class RemoveReasonFromClosures < ActiveRecord::Migration[8.1]
  def change
    remove_column :closures, :reason
  end
end
