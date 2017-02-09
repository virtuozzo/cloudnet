require 'rails_helper'

describe DockerProvisionerTasks do
  let!(:server) {FactoryGirl.create :server, root_password: 'myPass'}
  let(:prov_params) {{role: 'new_role', ip: '123.456.789.1', password: 'myPass', username: 'root', extra_vars: nil}}
  subject {DockerProvisionerTasks.new}
  
  it 'prepres call for server creation' do
    conn = double('Faraday')
    expect(subject).to receive(:connection).and_return(conn)
    expect(conn).to receive(:post).with('/job', prov_params)
    subject.create(server.id, "new_role")
  end
end
