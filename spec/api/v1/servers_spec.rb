require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  let(:user) { FactoryGirl.create :user, confirmed_at: Date.today }
  let(:api_key) { FactoryGirl.create :api_key, user: user}
  let(:encoded) { Base64.encode64("#{user.email}:#{api_key.key}") }
  let(:good_header) { {"Authorization": "Basic #{encoded}", "Accept-Version": "v1"} }
  let!(:server_list) { FactoryGirl.create_list :server, 3, user: user }
  let(:server_id) { server_list[0].id }
  describe 'Servers methods' do
    it_behaves_like "api authentication", "servers/1"

    it 'returns all servers for a current user' do
      get "#{api}/servers", nil, good_header
      body = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(body).to be_an Array
      expect(body.count).to eq user.servers.count
      expect(body.first['template']).to be_a Hash
      expect(body.first['ip_addresses']).to be_an Array
    end

    context 'GET /server/:id' do
      it 'returns a server if a user is authorized' do
        get "#{api}/servers/#{server_id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(body).to be_a Hash
        expect(body['id']).to eq server_id
      end

      it 'returns "not found" if a user is not authorized' do
        non_authorized_server = FactoryGirl.create :server
        get "#{api}/servers/#{non_authorized_server.id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.status).to eq 404
      end
    end

    context 'DELETE /server/:id' do
      it 'destroys a server if a user is authorized' do
        server_task_double = double('ServerTask', perform: true)
        expect(ServerTasks).to receive(:new).and_return(server_task_double)
        expect(user.account.credit_notes.count).to eq 0
        expect {delete "#{api}/servers/#{server_id}", nil, good_header}. to change {Server.count}.by(-1)
        expect(user.account.credit_notes.count).to eq 1
        expect(response.body).to be_empty
        expect(response.status).to eq 204
      end

      it 'returns "not found" if a user is not authorized' do
        non_authorized_server = FactoryGirl.create :server
        delete "#{api}/servers/#{non_authorized_server.id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.body).to eq "{\"error\":\"Not Found\"}"
        expect(response.status).to eq 404
      end
    end

    context 'POST /server' do
      it 'creates a server if a user is authorized' do
        user.update(vm_max: 4)
        new_server = Server.find(server_id)
        expect(user.account.invoices.count).to eq 0
        expect_any_instance_of(ServerWizard).to receive(:cost_for_hours).and_return(0)
        expect_any_instance_of(ServerWizard).to receive(:calculate_remaining_cost).and_return(0)
        expect_any_instance_of(ServerWizard).to receive(:save_server_details).and_return(new_server)
        expect(CreateServer).to receive(:new).and_return(double(process: {'id' => 3}))

        post "#{api}/servers", { template_id: Template.first.id }, good_header
        body = JSON.parse(response.body)
        expect(body['name']).to eq new_server.name
        expect(response.status).to eq 201
        expect(user.account.invoices.count).to eq 1
        expect(user.account.credit_notes.count).to eq 0
      end

      it 'returns error if no template_id in params' do
        post "#{api}/servers", nil, good_header
        expect(response.body).to eq "{\"error\":\"template_id is missing\"}"
        expect(response.status).to eq 400
      end

      it 'returns error if non existing template_id in params' do
        post "#{api}/servers", { template_id: Template.maximum(:id) + 1 }, good_header
        expect(response.body).to eq "{\"error\":\"Not Found\"}"
        expect(response.status).to eq 404
      end

      it 'returns error if out of scope cpus in params' do
        post "#{api}/servers", { template_id: Template.first.id, cpus: 0 }, good_header
        expect(response.body).to eq "{\"error\":\"cpus does not have a valid value\"}"
        expect(response.status).to eq 400

        post "#{api}/servers", { template_id: Template.first.id, cpus: 7 }, good_header
        expect(response.body).to eq "{\"error\":\"cpus does not have a valid value\"}"
        expect(response.status).to eq 400
      end

      it 'returns error if out of scope memory in params' do
        post "#{api}/servers", { template_id: Template.first.id, memory: 127 }, good_header
        expect(response.body).to eq "{\"error\":\"memory does not have a valid value\"}"
        expect(response.status).to eq 400

        post "#{api}/servers", { template_id: Template.first.id, memory: 8193 }, good_header
        expect(response.body).to eq "{\"error\":\"memory does not have a valid value\"}"
        expect(response.status).to eq 400
      end

      it 'returns error if out of scope disk size in params' do
        post "#{api}/servers", { template_id: Template.first.id, disk_size: 4 }, good_header
        expect(response.body).to eq "{\"error\":\"disk_size does not have a valid value\"}"
        expect(response.status).to eq 400

        post "#{api}/servers", { template_id: Template.first.id, disk_size: 121 }, good_header
        expect(response.body).to eq "{\"error\":\"disk_size does not have a valid value\"}"
        expect(response.status).to eq 400
      end
    end

    context 'PUT /server/:id' do
      before :each do
        expect_any_instance_of(ServerWizard).to receive(:cost_for_hours).and_return(0)
        expect_any_instance_of(ServerWizard).to receive(:calculate_remaining_cost).and_return(0)
        expect_any_instance_of(ServerWizard).to receive(:request_server_edit).and_return(true)
        @server = Server.find(server_id)
        @account = user.account
        expect(@account.invoices).to be_empty
        expect(@account.credit_notes).to be_empty
      end

      it 'changes the number of cpus and generates invoice and credit_note' do
        expect(@server.cpus).to eq 1
        put "#{api}/servers/#{server_id}", { cpus: 2 }, good_header
        body = JSON.parse(response.body)
        expect(body['cpus']).to eq 2
        expect(response.status).to eq 200

        @server.reload
        expect(@server.cpus).to eq 2
        expect(@account.invoices.count).to eq 1
        expect(@account.credit_notes.count).to eq 1
      end

      it 'changes memory and generates invoice and credit_note' do
        expect(@server.memory).to eq 512
        put "#{api}/servers/#{server_id}", { memory: 1000 }, good_header
        body = JSON.parse(response.body)
        expect(body['memory']).to eq 1000
        expect(response.status).to eq 200

        @server.reload
        expect(@server.memory).to eq 1000
        expect(@account.invoices.count).to eq 1
        expect(@account.credit_notes.count).to eq 1
      end
    end
  end
end
