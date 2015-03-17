ENV['RAILS_ENV'] ||= 'production'
require_relative '../../config/environment'

def calculate_revenue(month, year)
  dt = Time.new(year, month, 1)

  puts "location_id,provider,user_email,server_id,invoice_created_at,invoice_state,memory,cores,disk,bandwidth,coupon_percentage,invoice_type"
  
  prepaid_invoices((dt.beginning_of_month..dt.end_of_month))
  payg_invoices((dt.beginning_of_month..dt.end_of_month))
  credit_notes((dt.beginning_of_month..dt.end_of_month))
end


def prepaid_invoices(date_range)
  all_invoices = Invoice.with_deleted.where(created_at: date_range)
  prepaid_invoices = all_invoices.where("invoices.invoice_type = 'prepaid' OR invoices.invoice_type IS NULL")

  prepaid_invoices.each do |invoice|
    invoice.invoice_items.each do |item|
      puts print_row_for_item(item, 'invoice_item_prepaid', invoice.state, invoice.account.user, 
        get_costs(item.metadata), invoice.coupon)
    end
  end
end

def payg_invoices(date_range)
  all_invoices = Invoice.with_deleted.where(created_at: date_range)
  payg_invoices = all_invoices.where("invoices.invoice_type = 'payg'")

  payg_invoices.each do |invoice|
    invoice.invoice_items.each do |item|
      transactions = ServerHourlyTransaction.with_deleted.where(id: item.metadata[:transactions]).without_duplicates
      costs = {memory: 0.0, cpu: 0.0, disk: 0.0, bandwidth: 0.0}
      transactions.each do |tx|
        costs[:memory] += tx.metadata[0][:net_cost].to_f
        costs[:cpu] += tx.metadata[1][:net_cost].to_f
        costs[:disk] += tx.metadata[2][:net_cost].to_f
        costs[:bandwidth] += tx.metadata[3][:net_cost].to_f
      end

      costs_array = [:memory, :cpu, :disk, :bandwidth].map { |k| Invoice.pretty_total(costs[k]) }
      puts print_row_for_item(item, 'invoice_item_payg', invoice.state, invoice.account.user, 
        costs_array, invoice.coupon)
    end
  end
end

def credit_notes(date_range)
  credit_note_items = CreditNoteItem.with_deleted.where(created_at: date_range)
  credit_note_items.each do |item|
      puts print_row_for_item(item, 'credit_note_prepaid', item.credit_note.state, 
        item.credit_note.account.user, get_costs(item.metadata), item.credit_note.coupon)
  end
end

def print_row_for_item(item, type, state, user, costs, coupon)
  server_id         = item.source_id
  location          = item.source.location
  metadata          = item.metadata
  coupon_percentage = if coupon then coupon.percentage else '0' end
  return "#{location.id},#{location.city} - #{location.provider},#{user.email},#{item.created_at},#{server_id},#{state},#{costs.join(',')},#{coupon_percentage},#{type}"
end

def get_costs(metadata)
  memory_cost       = Invoice.pretty_total(metadata[0][:net_cost].to_f)
  cores_cost        = Invoice.pretty_total(metadata[1][:net_cost].to_f)
  disk_cost         = Invoice.pretty_total(metadata[2][:net_cost].to_f)
  bandwidth_cost    = Invoice.pretty_total(metadata[3][:net_cost].to_f)
  return [memory_cost, cores_cost, disk_cost, bandwidth_cost]
end

if ARGV.length != 2
  puts "Usage: ruby invoice_item_breakdown.rb <month> <year>"
  exit 1
end

month = ARGV[0].to_i
year = ARGV[1].to_i
calculate_revenue(month, year)