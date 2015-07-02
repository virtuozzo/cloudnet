shared_context :pingdom_env do
  before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PINGDOM_USER").and_return "sampe@user.com"
    allow(ENV).to receive(:[]).with("PINGDOM_PASS").and_return "myPass"
    allow(ENV).to receive(:[]).with("PINGDOM_KEY").and_return "myApiKey"
  end
end