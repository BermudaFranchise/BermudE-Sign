# frozen_string_literal: true

class AddRbacRolesToUsers < ActiveRecord::Migration[7.1]
  def up
    # Ensure role column allows the new values (it's already a string, no schema change needed).
    # Set any blank/null roles to 'admin' for safety.
    execute <<-SQL
      UPDATE users SET role = 'admin' WHERE role IS NULL OR role = '';
    SQL

    # Add an index on role for faster filtering
    add_index :users, :role, if_not_exists: true
  end

  def down
    remove_index :users, :role, if_exists: true

    # Revert non-admin roles back to admin
    execute <<-SQL
      UPDATE users SET role = 'admin' WHERE role NOT IN ('admin');
    SQL
  end
end
