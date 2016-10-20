require "rails_helper"

RSpec.describe AdminMailer, :type => :mailer do
  let(:user) { FactoryGirl.create(:user, notif_delivered: 11) }
  let(:from) { Mail::Address.new(ENV['MAILER_ADMIN_DEFAULT_FROM']) }

  describe "shutdown_action" do
    let(:mail) { AdminMailer.shutdown_action(user) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: Automatic shutdown - #{user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        send_mail :shutdown_action, user
      end

      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end

      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match("Admin SHUTDOWN notification!")
        expect(response).to match("The automatic shutdown was performed on all servers of #{CGI.escapeHTML(user.full_name)}.")
        expect(response).to include("negative balance on this account by #{balance}")
        expect(response).to match("There were 11 warnings delivered to that user.")
        expect(response).to match("profile: #{admin_user_url(user) }")
        expect(response).to match("After #{user.notif_before_destroy} notifications")
      end
    end
  end

  describe "destroy_warning" do
    let(:mail) { AdminMailer.destroy_warning(user) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: DESTROY warning! - #{user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        send_mail :destroy_warning, user
      end

      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end

      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match("Admin DESTROY warning!")
        expect(response).to match("all servers of #{CGI.escapeHTML(user.full_name)} will be destroyed soon.")
        expect(response).to include("negative balance on this account by #{balance}")
        expect(response).to match("There were 12 warnings delivered to that user.")
        expect(response).to match("profile: #{admin_user_url(user) }")
        expect(response).to match("After #{user.notif_before_destroy} notifications")
      end
    end
  end

  describe "request_for_server_destroy" do
    let(:mail) { AdminMailer.request_for_server_destroy(user) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: DESTROY request! - #{user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        send_mail :request_for_server_destroy, user
      end

      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end

      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match("Admin DESTROY request!")
        expect(response).to match("all servers of #{CGI.escapeHTML(user.full_name)} are scheduled to be destroyed.")
        expect(response).to include("negative balance on this account by #{balance}")
        expect(response).to match("There were 11 warnings delivered to that user.")
        expect(response).to match("profile: #{admin_user_url(user) }")
        expect(response).to match("log in to your admin account and confirm destroy")
      end
    end
  end

  describe "destroy_action" do
    let(:mail) { AdminMailer.destroy_action(user) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Cloud.net: Automatic destroy - #{user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        send_mail :destroy_action, user
      end

      it "assigns variables" do
        expect(assigns(:user)).to eq user
        expect(assigns(:pretty_negative_balance)).to eq "$0.00"
      end

      it "renders the body" do
        balance = assigns(:pretty_negative_balance)

        expect(response).to match("Admin DESTROY notification!")
        expect(response).to match("The automatic destroy was performed on all servers of #{CGI.escapeHTML(user.full_name)}.")
        expect(response).to include("negative balance on this account by #{balance}")
        expect(response).to match("There were 11 warnings delivered to that user.")
        expect(response).to match("profile: #{admin_user_url(user) }")
      end
    end
  end

  describe 'notify faulty server' do
    let(:server) { FactoryGirl.create(:server) }
    let(:mail) { AdminMailer.notify_faulty_server(server, true, true) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("#{ENV['BRAND_NAME']}: Faulty server for user #{server.user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        send_mail :notify_faulty_server, server, true, true
      end

      it "assigns variables" do
        expect(assigns(:server)).to eq server
        expect(assigns(:no_disk)).to be_truthy
        expect(assigns(:no_ip)).to be_truthy
        expect(assigns(:link_to_onapp_server)).to be
      end

      it "renders the body" do
        expect(response).to match("Server issues warning.")
        expect(response).to match(CGI.escapeHTML(server.user.full_name))
        expect(response).to match("storage attached")
        expect(response).to match("and no ip address")
        expect(response).to match(admin_server_url(server))
        expect(response).to match(assigns(:link_to_onapp_server))
      end
    end
  end

  describe 'notify automatic invoice' do
    let(:server) { FactoryGirl.create(:server) }
    let(:old_server_specs) { Server.new server.as_json }
    let(:mail) { AdminMailer.notify_automatic_invoice(server, old_server_specs) }

    it "fills mailer queue" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders the headers" do
      expect(mail.subject).to eq("#{ENV['BRAND_NAME']}: VM parameters discrepancy - automatic billing for user #{server.user.full_name}")
      expect(mail.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
      expect(mail.from).to eq([from.address])
    end

    context "rendering" do
      before(:each) do
        old_server_specs.cpus = server.cpus + 1
        old_server_specs.memory = server.memory + 100
        old_server_specs.disk_size = server.disk_size + 10
        send_mail :notify_automatic_invoice, server, old_server_specs
      end

      it "assigns variables" do
        expect(assigns(:server)).to eq server
        expect(assigns(:link_to_onapp_server)).to be
        expect(assigns(:old_server_specs)).to eq old_server_specs
      end

      it "renders the body" do
        expect(response).to match("Server automatic billing.")
        expect(response).to match(CGI.escapeHTML(server.user.full_name))
        expect(response).to match("<p>Old server parameters on #{ENV['BRAND_NAME']}:</p>")
        expect(response).to match("cpus: #{old_server_specs.cpus}")
        expect(response).to match("memory: #{old_server_specs.memory}")
        expect(response).to match("disk size: #{old_server_specs.disk_size}")
        expect(response).to match(/New server parameters \(got from OnApp\):/)
        expect(response).to match("cpus: #{server.cpus}")
        expect(response).to match("memory: #{server.memory}")
        expect(response).to match("disk size: #{server.disk_size}")
        expect(response).to match(admin_server_url(server))
        expect(response).to match(assigns(:link_to_onapp_server))
      end
    end
  end
end
