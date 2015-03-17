class Charge < ActiveRecord::Base
  belongs_to :invoice
  has_one :account, through: :invoice

  validates :amount, :invoice, :source_type, :source_id, presence: true

  def source
    @source ||= source_type.constantize.with_deleted.find(source_id) if source_type
  end

  def source=(source)
    self.source_type = source.class.to_s
    self.source_id   = source.id
  end
end
