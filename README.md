[ ![Codeship Status for onapp/cloudnet-cp](https://codeship.com/projects/60dc88f0-5d41-0132-4110-6a9a57a3d30a/status)](https://codeship.com/projects/51043)

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
