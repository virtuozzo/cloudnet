json.extract!(
  backup,
  :id,
  :built,
  :identifier,
  :locked,
  :min_disk_size,
  :min_memory_size,
  :backup_size
)

json.backup_created backup.backup_created.iso8601
json.created_at backup.created_at.iso8601
json.updated_at backup.updated_at.iso8601
