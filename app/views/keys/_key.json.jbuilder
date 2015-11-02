json.extract!(
  key,
  :id,
  :title,
  :key
)

json.created_at key.created_at.iso8601
json.updated_at key.updated_at.iso8601
