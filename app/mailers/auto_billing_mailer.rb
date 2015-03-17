class AutoBillingMailer < ActionMailer::Base
  default from: 'billing@cloud.net'

  def unpaid(user, invoice)
    filename = "CloudDotNet Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end

  def partially_paid(user, invoice)
    filename = "CloudDotNet Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end

  def paid(user, invoice)
    filename = "CloudDotNet Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end

  def payg_unpaid(user, invoice)
    filename = "CloudDotNet PAYG Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net PAYG Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end

  def payg_partially_paid(user, invoice)
    filename = "CloudDotNet PAYG Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net PAYG Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end

  def payg_paid(user, invoice)
    filename = "CloudDotNet PAYG Invoice #{invoice.invoice_number}.pdf"
    attachments[filename] = InvoicePdf.create_invoice(invoice, view_context).render

    @user = user
    mail to: @user.email, subject: "Cloud.net PAYG Invoice Generated - #{invoice.created_at.strftime('%d %b %Y')}"
  end
end
