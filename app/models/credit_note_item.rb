class CreditNoteItem < ActiveRecord::Base
  include Metadata

  acts_as_paranoid
  belongs_to :credit_note

  validates :credit_note, presence: true
  
  scope :trial_credits, -> { where('description = ?', 'Trial Credit') }
  scope :manual_credits, -> { where('source_type = ?', 'User') }

  def net_cost
    (read_attribute(:net_cost) || 0).round(-3)
  end

  def tax_cost
    if read_attribute(:tax_cost)
      read_attribute(:tax_cost).round(-3)
    else
      (net_cost * credit_note.tax_rate).round(-3)
    end
  end

  def total_cost
    net_cost + tax_cost
  end

  def tax_code
    credit_note.tax_code
  end

  def tax_rate
    credit_note.tax_rate
  end

  def source
    @source ||= source_type.constantize.with_deleted.find(source_id) if source_type
  end

  def source=(source)
    self.source_type = source.class.to_s
    self.source_id   = source.id
  end
end
