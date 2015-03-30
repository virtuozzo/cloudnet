require 'prawn'
require 'prawn/table'

class BillingPdf < Prawn::Document
  def initialize(*_args)
    super()
  end

  def header(title)
    image "#{Rails.root}/app/assets/images/cloudnetbeta-large.png", width: 138, height: 55

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
    address = if @account.address1
      # If the user has manually provided an 'Invoice address' prefer that
      @account
    else
      # Otherwise default to the primary card's billing address
      @account.billing_address
    end

    if address.present?
      text address[:address1]
      text address[:address2] if address[:address2].present?
      text "#{address[:city]}, #{address[:region]}"
      text address[:postal]
      text IsoCountryCodes.find(address[:country]).name rescue IsoCountryCodes::UnknownCodeError
    end
  end

  private

  def header_text_options
    { color: '777777', size: 8 }
  end
end
