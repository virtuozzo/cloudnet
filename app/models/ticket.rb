class Ticket < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :user
  belongs_to :server
  has_many :ticket_replies, dependent: :destroy

  enum_field :status, allowed_values: [:new, :open, :pending, :hold, :solved, :closed], default: :new
  enum_field :department, allowed_values: Helpdesk.departments.keys, default: Helpdesk.departments.keys.first

  validates :subject, :body, :user, presence: true

  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }

  def process_reply(reply)
    existing = ticket_replies.find_by_reference(reply[:id].to_s)
    existing = true if reply[:body] == body && reply[:created_at] == created_at

    if existing.nil?
      params = { sender: reply[:author], body: reply[:body], created_at: reply[:created_at], reference: reply[:id].to_s }
      if reply[:author_email] == user.email
        params.merge!(user: user)
        params[:sender] = nil
      end

      ticket_replies.create! params
    end
  end

  def process_status(status)
    self.update!(status: status.downcase.to_sym)
  end

  def completed?
    [:closed, :solved].include?(status.downcase)
  end

  private

  def server_is_empty_or_valid
    unless server.nil? || server.user == user
      errors.add(:server, 'is invalid')
    end
  end
end
