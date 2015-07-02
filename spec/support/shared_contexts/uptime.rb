shared_context :pingdom_env do
  before(:each) do
    allow(KEYS).to receive(:[]).with(:pingdom).and_return({
      :api_key=>"myAPIkey", 
      :user=>"myUser", 
      :pass=>"myPass"
      })
  end
end