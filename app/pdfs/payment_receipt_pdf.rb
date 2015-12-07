class PaymentReceiptPdf < BillingPdf
  include ActionView::Helpers::TextHelper

  def initialize(receipt, view)
    super
    @receipt = receipt
    @account = receipt.account
    @view = view

    font_size 9
    header('PAYMENT RECEIPT')
    addresses_and_receipt_details
    receipt_table
    receipt_summary
    receipt_payment
  end

  def addresses_and_receipt_details
    float do
      span((bounds.width / 2) - 20, position: :left) do
        text 'Payment by', style: :bold
        move_down 10
        text @receipt.account.user.full_name
        text @receipt.account.user.email
        move_down 5

        address
      end
    end

    float do
      span((bounds.width / 2) - 20, position: :right) do
        items = [
          ['Receipt Number',      @receipt.receipt_number],
          ['Receipt Date',        @receipt.created_at.strftime('%d/%m/%Y')],
          ['Receipt Currency',    'USD']
        ]

        table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
          style(column(0), align: :right, background_color: 'e9e9e9', font_style: :bold, width: 130, inline_format: true)
        end
      end
    end

    move_down 130
  end

  def receipt_table
    items = [['Product Name/Description', 'Tax Value', 'Net Value']]
    items << receipt_item

    table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
      style(column(1..2), width: 100, align: :center, valign: :center)
      style(column(0), padding: [8] * 4)
      style(row(0), align: :center, background_color: 'e9e9e9', font_style: :bold, padding: [5] * 4)
    end

    move_down 10
  end

  def receipt_summary
    page_width = bounds.width

    float do
      span(200, position: :right) do
        items = [
          ['Net Total',     Invoice.pretty_total(@receipt.net_cost)],
          ['Tax Total',     Invoice.pretty_total(0)],
          ['Receipt Total', Invoice.pretty_total(@receipt.net_cost)]
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

  def receipt_payment
    items = [
      ['Payment Receipt'],
      ['Your payment has been credited to your Wallet account and can be used to pay off invoices']
    ]

    table items, width: bounds.width, cell_style: { border_widths: [1] * 4, border_colors: ['999999'] * 4 } do
      style(row(0), background_color: 'e9e9e9', font_style: :bold, padding: [5] * 4)
    end
  end

  private

  def formatted_cell(text)
    Prawn::Table::Cell::Text.new(self, [0, 0], content: text, inline_format: true)
  end

  def receipt_item
    desc_items = [
      [formatted_cell("<b>Payment via #{@receipt.pretty_pay_source}</b>")],
      [formatted_cell("<font size='8'></font>")]
    ]

    [
      Prawn::Table.new(desc_items - [nil], self, cell_style: { border_widths: [0] * 4, padding: [1, 5, 1, 5] }),
      Invoice.pretty_total(0),
      Invoice.pretty_total(@receipt.net_cost)
    ]
  end
end
