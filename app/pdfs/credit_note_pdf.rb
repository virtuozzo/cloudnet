class CreditNotePdf < BillingPdf
  include ActionView::Helpers::TextHelper

  def initialize(credit_note, view)
    super
    @credit_note = credit_note
    @account = credit_note.account
    @view = view

    font_size 9
    header('CREDIT NOTE')
    addresses_and_credit_note_details
    credit_note_table
    credit_note_summary
    credit_note_payment
  end

  def addresses_and_credit_note_details
    float do
      span((bounds.width / 2) - 20, position: :left) do
        text 'Credited to', style: :bold
        move_down 10
        text @credit_note.account.user.full_name
        text @credit_note.account.user.email
        move_down 5

        address
      end
    end

    float do
      span((bounds.width / 2) - 20, position: :right) do
        items = [
          ['Credit Note Number',  @credit_note.credit_number],
          ['Credit Note Date',    @credit_note.created_at.strftime('%d/%m/%Y')],
          ['Credit Note Currency', 'USD'],
          ['Customer VAT Number', @credit_note.vat_number]
        ]

        table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
          style(column(0), align: :right, background_color: 'e9e9e9', font_style: :bold, width: 130, inline_format: true)
        end
      end
    end

    move_down 130
  end

  def credit_note_table
    items = [['Product Name/Description', 'Tax Value', 'Net Value']]
    @credit_note.credit_note_items.each { |item| items << credit_note_item(item) }

    if @credit_note.coupon.present?
      items << coupon_discount
    end

    table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
      style(column(1..2), width: 100, align: :center, valign: :center)
      style(column(0), padding: [8] * 4)
      style(row(0), align: :center, background_color: 'e9e9e9', font_style: :bold, padding: [5] * 4)
    end

    move_down 10
  end

  def coupon_discount
    desc_items = [[formatted_cell("<b>Coupon: #{truncate(@credit_note.coupon.description, length: 60)}</b>")]]
    [
      Prawn::Table.new(desc_items - [nil], self, cell_style: { border_widths: [0] * 4, padding: [1, 5, 1, 5] }),
      Invoice.pretty_total(@credit_note.tax_cost - @credit_note.pre_coupon_tax_cost),
      Invoice.pretty_total(@credit_note.net_cost - @credit_note.pre_coupon_net_cost)
    ]
  end

  def credit_note_summary
    page_width = bounds.width

    float do
      span(300, position: :left) do
        net_cost_gbp = Invoice.pretty_total(Invoice.in_gbp(@credit_note.net_cost), '£')
        tax_cost_gbp = Invoice.pretty_total(Invoice.in_gbp(@credit_note.tax_cost), '£')

        items = [
          [{ content: 'Tax Summary (in GBP)', colspan: 4 }],
          ['Tax Code', 'Tax Rate', 'Net Value', 'Tax Value'],
          [@credit_note.tax_code, "#{(@credit_note.tax_rate * 100)}%", net_cost_gbp, tax_cost_gbp]
        ]

        table items, width: page_width - 220, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
          style(row(0..1), background_color: 'e9e9e9', font_style: :bold, padding: [5] * 4)
          style(row(0..2), align: :center)
        end
      end
    end

    float do
      span(200, position: :right) do
        items = [
          ['Net Total',     Invoice.pretty_total(@credit_note.net_cost)],
          ['Tax Total',     Invoice.pretty_total(@credit_note.tax_cost)],
          ['Credit Note Total', Invoice.pretty_total(@credit_note.total_cost)]
        ]

        table items, width: 200, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
          style(column(0), align: :right, background_color: 'e9e9e9', font_style: :bold, inline_format: true)
          style(column(0..1), width: 100)
          style(column(1), align: :center)
        end
      end
    end

    move_down 90
  end

  def credit_note_payment
    items = [
      ['Credit Note Credit'],
      ['Your credit note balance will be credited to your account and will be automatically used to pay any open invoices']
    ]

    table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
      style(row(0), background_color: 'e9e9e9', font_style: :bold, padding: [5] * 4)
    end
  end

  private

  def formatted_cell(text)
    Prawn::Table::Cell::Text.new(self, [0, 0], content: text, inline_format: true)
  end

  def credit_note_item(item)
    desc_items = [[formatted_cell("<b>#{truncate(item.description, length: 60)}</b>")]]

    if item.metadata.present?
      item.metadata.each { |meta| desc_items << metadata_content(meta) }
    end

    [
      Prawn::Table.new(desc_items - [nil], self, cell_style: { border_widths: [0] * 4, padding: [1, 5, 1, 5] }),
      Invoice.pretty_total(item.tax_cost),
      Invoice.pretty_total(item.net_cost)
    ]
  end

  def metadata_content(metadata)
    return if !metadata.present? || !metadata.key?(:description)

    content = "<font size='8'>"
    content += "<i>#{metadata[:name]}</i>: " if metadata.key?(:name)
    content += metadata[:description]
    content += ". Net Value: #{Invoice.pretty_total(metadata[:net_cost].to_f)}" if metadata.key?(:net_cost)
    content += '</font>'
    [formatted_cell(content)]
  end
end
