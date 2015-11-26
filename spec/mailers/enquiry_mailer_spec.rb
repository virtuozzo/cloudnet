require "rails_helper"

RSpec.describe EnquiryMailer, :type => :mailer do
  describe "contact_page" do
    let(:params) {{name: "John Dow", email: "john.dow@ibm.ru", 
                   phone: "07438 222 444", msg: "Hello. `I know you!"}}
    let(:mail) { EnquiryMailer.contact_page(params) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end
    
    it "renders the headers" do
      expect(mail.subject).to eq("Enquiry from contact page")
      expect(mail.to).to eq(ENV['MAILER_ENQUIRY_RECIPIENTS'].split(','))
      expect(mail.from).to eq([params[:email]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(params[:name])
      expect(mail.body.encoded).to match(params[:phone])
      expect(mail.body.encoded).to match(params[:msg])
    end
  end

end
