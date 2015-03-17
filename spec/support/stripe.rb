require 'rails_helper'

# When our user is created, we don't need an associated Stripe user for most
# of our tests so skip the callback unless we need it
User.skip_callback(:create, :before, :create_payment_customer)
