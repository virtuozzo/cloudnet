# Keep track of PAYG servers
class ServerHourlyTransaction < ActiveRecord::Base
  include Metadata
  acts_as_paranoid

  belongs_to :account
  belongs_to :server
  belongs_to :coupon

  validates :server, :net_cost, :account, presence: true

  # TODO: Temporary fix. Remove once DB is cleaned.
  # There was a bug where the worker process processed transactions twice. This scope exists so
  # that the duplicate transactions can stay in the DB whilst their audited. This scope should be
  # removed once the DB is cleaned.
  scope :without_duplicates, ->{ where(duplicate: false) }
  scope :billable, -> { order(net_cost: :desc, created_at: :asc).limit(Account::HOURS_MAX) }

  def self.generate_transaction(account, server, coupon = nil)
    transaction = ServerHourlyTransaction.new(server: server, coupon: coupon, account: account)
    transaction
  end

  def cost
    coupon_multiplier = (1 - coupon_percentage)
    net_cost * coupon_multiplier
  end

  def coupon_percentage
    if coupon.present? then coupon.percentage_decimal else 0 end
  end

  def server=(server)
    self.server_id = server.id
    invoice_item = server.generate_invoice_item(1)
    self.net_cost = invoice_item[:net_cost]
    self.metadata = invoice_item[:metadata]
  end
end
