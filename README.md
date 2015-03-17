[ ![Codeship Status for OnApp/cloudnet](https://codeship.com/projects/6e11e150-aeee-0132-a36c-2a23891ee2d0/status?branch=master)](https://codeship.com/projects/69018)

#Control Panel for Cloud.net

##Local Installation

```sh
# First ask for a copy of a `.env` file, it contains ENV vars for various sensitive config
# credentials. Place it in the root of the project tree.
bundle install
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec guard
```

Run the server with `rails server` and goto http://localhost:3000

Logins are;   
**Admin**   
user: admin@cloud.net   
pass: adminpassword

**Normal user**   
user: user@cloud.net   
pass: password
