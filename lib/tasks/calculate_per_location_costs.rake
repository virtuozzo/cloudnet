task calculate_per_location_costs: :environment do
  year = (ENV['YEAR'] || 2015).to_i
  month = (ENV['MONTH'] || 1).to_i
  lower = Date.new(year, month)
  upper = lower.end_of_month
  range = lower..upper

  invoices =
    Invoice
    .with_deleted
    .where(state: 'paid')
    .where(created_at: range)

  provider_totals = {}
  invoices.each do |invoice|
    # Given the amount charged in cash for this invoice, share the cash amongst the providers
    # Ignore the 'CreditNote' type as we're only concerned with actual cash
    cash =
      invoice
      .charges
      .where(source_type: %w(BillingCard PaymentReceipt))
      .to_a
      .sum(&:amount)
    next if cash == 0

    # Total cost will be used to calculate the fraction each provider took from the total
    invoice_total_cost = invoice.invoice_items.to_a.sum(&:total_cost)
    next if invoice_total_cost == 0

    # Group invoice items by provider
    by_provider = Hash[
      invoice.invoice_items.group_by do |ii|
        Server.with_deleted.find(ii.source_id).location.provider.downcase
      end
    ]

    # Sum the invoice item cost per provider and return it as a fraction of the total
    by_provider.map do |provider, items|
      provider_totals[provider] ||= 0
      ratio = items.sum(&:total_cost).to_f / invoice_total_cost.to_f
      provider_totals[provider] += ratio * cash
    end
  end

  puts "#{Date::MONTHNAMES[month]} #{year}"
  puts 'Provider: charges (including coupon reductions)'
  provider_totals.each do |provider, charges|
    charges_pretty = Invoice.pretty_total(charges)
    puts "#{provider}: #{charges_pretty}"
  end
end
