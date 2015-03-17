class ServerBackup < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :server

  validates :backup_id, :identifier, :backup_created, :server, presence: true

  def backup_size_mb
    backup_size / 1024
  end

  def self.create_backup(server, backup)
    ServerBackup.create(
      backup_id:          backup['id'],
      built:              backup['built'],
      built_at:           backup['built_at'],
      backup_created:     backup['created_at'],
      identifier:         backup['identifier'],
      locked:             backup['locked'],
      disk_id:            backup['disk_id'],
      min_disk_size:      backup['min_disk_size'],
      min_memory_size:    backup['min_memory_size'],
      server:             server,
      backup_size:        backup['backup_size']
    )
  end
end
