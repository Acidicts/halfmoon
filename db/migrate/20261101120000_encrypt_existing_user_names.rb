class EncryptExistingUserNames < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      # Re-write the name attribute to trigger encryption
      user.update_column(:name, user.name)
    end
  end

  def down
    # No reversal – names remain encrypted
  end
end
