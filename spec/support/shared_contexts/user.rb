shared_context :with_user do
  before :each do
    # Always generating the same user credentials means that recording of new VCR cassettes doesn't
    # get triggered.
    allow_any_instance_of(UserTasks).to receive(:generate_user_credentials).and_return(
      login: 'auto_rspec_user',
      email: 'auto_rspec_user@onapp.com',
      password: 'Abcdef123456!'
    )
    
    # Creating a cloud.net user without stripe triggers callback to create a Stripe user
    @user = FactoryGirl.create :user_without_stripe
    @user.reload # Update the new stripe data

    # Associate a fake card with the user's account. Using build() to avoid user creation
    # callbacks
    billing_card = FactoryGirl.build(:billing_card, account: @user.account)
    customer = Stripe::Customer.retrieve(@user.account.gateway_id)
    card = customer.cards.create(
      card: {
        number: '4242424242424242',
        exp_month: billing_card.expiry_month,
        exp_year: billing_card.expiry_year,
        cvc: '424'
      }
    )
    billing_card.processor_token = card.id
    billing_card.save!
  end

  after :each do
    # Destroy dependent objects first
    # TODO: automatically detect user's dependent objects
    if @server
      @server.wait_until_ready
      @server_task.perform(:destroy, @user.id, @server.id)
    end

    api_user = Squall::User.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    # First call sets user's flag to deleted
    api_user.delete(@user.onapp_id)
    start = Time.now
    begin
      # Second call removes them from Onapp's DB
      api_user.delete(@user.onapp_id)
    rescue Faraday::ClientError => e
      break if Time.now - start > 10.minutes
      # Sometimes need to wait for Onapp transactions to complete
      retry if e.response[:body] =~ /Please wait/
    end
  end
end
