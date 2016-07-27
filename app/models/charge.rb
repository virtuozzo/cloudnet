class Charge < ActiveRecord::Base
  include SiftProperties
  
  belongs_to :invoice
  has_one :account, through: :invoice

  validates :amount, :invoice, :source_type, :source_id, presence: true
  
  after_create :create_sift_event

  def source
    @source ||= source_type.constantize.with_deleted.find(source_id) if source_type
  end

  def source=(source)
    self.source_type = source.class.to_s
    self.source_id   = source.id
  end
  
  def charge_number
    "CH#{id.to_s.rjust(7, '0')}"
  end
  
  alias_method :number, :charge_number
  
  def create_sift_event
    CreateSiftEvent.perform_async("$transaction", sift_charge_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: account.user.id, source: 'Charge#create_sift_event' })
  end
end
