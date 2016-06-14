require 'prawn'
require 'prawn/table'

class BillingPdf < Prawn::Document
  def initialize(*_args)
    super()
  end

  def header(title)
    image "#{Rails.root}/app/assets/images/cloudnet-large.png", width: 91, height: 54

    move_down 10
    ENV['PDF_HEADER'].lines.each do |line|
      text line, header_text_options
    end

    last_y = cursor
    move_cursor_to bounds.height
    move_down 50
    text title, size: 14, align: :right, style: :bold
    move_cursor_to last_y
    move_down 30
  end

  def address
    address_parts = [
      :company_name,
      :address1,
      :address2,
      :address3,
      :address4,
      :country,
      :postal,
    ]
    # If the user has manually provided an 'Invoice address' then prefer that
    address = if address_parts.any? { |line| @account.send(line).present? }
      @account
    # Otherwise default to the primary card's billing address
    else
      @account.billing_address
    end

    if address.present?
      address_parts = address_parts.insert -2, :city, -1, :region # Add Stripe-specific parts
      address_parts.each do |line|
        text address[line] if address[line].present?
      end
      text IsoCountryCodes.find(address[:country]).name rescue IsoCountryCodes::UnknownCodeError
    end
  end

  private

  def header_text_options
    { color: '777777', size: 8 }
  end
end
