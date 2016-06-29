RSpec.shared_examples "api authentication" do |endpoint|
  let(:api) {'http://api.localhost.com'}
  let(:user) { FactoryGirl.create :user }
  let(:api_key) { FactoryGirl.create :api_key, user: user}
  let(:path) { "#{api}/#{endpoint}" }
  
  it 'returns error if no Authorization header' do
    get path
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to eq "Please provide an Authorization header"
  end
  
  it 'returns error if wrong Authorization header' do
    get path, nil, 'Authorization': "APIKEY 123"
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to include "Invalid Authorization header"
  end
  
  it 'returns error if no Authorization type in header' do
    encoded = Base64.encode64("#{user.email}abc:#{api_key.key}")
    get path, nil, 'Authorization': encoded
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to include "Invalid Authorization header"
  end
  
  it 'returns error if not encoded Authorization header' do
    get path, nil, 'Authorization': "Basic #{user.email}:#{api_key.key}"
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to include "Make sure you encoded64"
  end
  
  it 'returns error if wrong email' do
    encoded = Base64.encode64("#{user.email}abc:#{api_key.key}")
    get path, nil, 'Authorization': "Basic #{encoded}"
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to eq "Unauthorized"
  end
  
  it 'returns error if wrong token' do
    encoded = Base64.encode64("#{user.email}:#{api_key.key}abc")
    get path, nil, 'Authorization': "Basic #{encoded}"
    body = JSON.parse(response.body)
    expect(response.status).to eq 401
    expect(body['error']).to eq "Unauthorized"
  end
  
  it 'authorizes if correct credentials' do
    encoded = Base64.encode64("#{user.email}:#{api_key.key}")
    get path, nil, 'Authorization': "Basic #{encoded}"
    body = JSON.parse(response.body)
    expect([200, 404]).to include response.status
    expect(body).to be
  end

end
