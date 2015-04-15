task calculate_per_location_costs: :environment do
  year = (ENV['YEAR'] || 2015).to_i
  month = (ENV['MONTH'] || 1).to_i
  lower = Date.new(year, month)
  upper = lower.end_of_month
  range = lower..upper

  paid_invoices = Hash[
    InvoiceItem
    .joins(:invoice)
    .where(invoices: { state: ['paid', 'partially_paid'] })
    .where(source_type: 'Server')
    .where(created_at: range)
    .group_by { |ii| Server.with_deleted.find(ii.source_id).location.to_s }
    .map { |l| [l[0], l[1].sum(&:total_cost)] }
  ]

  credit_notes = Hash[
    CreditNoteItem
    .where(source_type: 'Server')
    .where(created_at: range)
    .group_by { |cn| Server.with_deleted.find(cn.source_id).location.to_s }
    .map { |l| [l[0], l[1].sum(&:total_cost)] }
  ]

  puts "#{Date::MONTHNAMES[month]} #{year}"
  puts 'Provider: invoices, credit_notes, total'
  paid_invoices.each do |provider, invoice_sum|
    credit_note_sum = credit_notes[provider] || 0
    invoice_sum_pretty = Invoice.pretty_total(invoice_sum)
    credit_note_sum_pretty = Invoice.pretty_total(credit_note_sum)
    total_pretty = Invoice.pretty_total(invoice_sum - credit_note_sum)
    puts "#{provider}: #{invoice_sum_pretty}, #{credit_note_sum_pretty}, #{total_pretty}"
  end
end
