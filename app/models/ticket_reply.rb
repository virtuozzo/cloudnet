class TicketReply < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :ticket
  belongs_to :user

  validates :ticket, :body, :sender, presence: true
  validate :ticket_not_completed, on: :create

  before_validation :set_sender_name
  after_save :touch_ticket

  def ticket_not_completed
    unless !ticket.completed? || reference
      errors.add(:ticket, 'is already marked as solved/closed')
    end
  end

  private

  def set_sender_name
    self.sender ||= user.full_name unless user.nil?
  end

  def touch_ticket
    ticket.touch
  end
end
