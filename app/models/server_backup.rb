class ServerBackup < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :server

  validates :backup_id, :identifier, :backup_created, :server, presence: true

  def backup_size_mb
    backup_size / 1024
  end
end
