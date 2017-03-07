This is a step-by-step guide to install Cloud.net on a bare metal or VPS *without* using Docker.

**Minimum requirements**

* A server running Ubuntu 16.04 LTS with at least 2GB of RAM.
* OnApp control panel with required permissions
* SMTP and few other third party logins

**Installation**

1. Create new user to run the app and add to sudo

  ```
  adduser cloudnet
  visudo
  ```
  
  Add this below 'root    ALL=(ALL) ALL'
  
  `cloudnet ALL=(ALL)NOPASSWD: ALL`
  
  Now, login as cloudnet user

2. Create a file called .gemrc in home folder, and insert the following

  `gem: --no-ri --no-rdoc`
  
3. Install the required libraries

  `sudo apt-get install git-core curl zlib1g-dev build-essential tcl libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs postgresql postgresql-contrib libpq-dev memcached`

4. Install Ruby

  ```
  cd /tmp
  wget https://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.10.tar.gz
  tar -xzvf ruby-2.1.10.tar.gz
  cd ruby-2.1.10/
  ./configure
  make
  sudo make install
  ```

5. Install bundler gem

  `sudo gem install bundler`

6. Setup and create Postgresql user and database

  ```
  sudo -u postgres createuser -s cloudnet
  sudo -u postgres psql
  \password cloudnet
  CREATE DATABASE cloudnet;
  \q
  ```

  Note the password for user cloudnet which we will use later.

7. Install and configure Redis

  Follow [this guide](https://gist.github.com/hackedunit/a53f0b5376b3772d278078f686b04d38) to install and configure Redis to start on boot using systemd.

8. Clone cloudnet repo from Github to app directory

  ```
  cd ~/
  git clone https://github.com/OnApp/cloudnet.git app
  ```

9. Configure the app

  Make a copy of dotenv.sample file and name it .env.production and update all the required configuration values. 

  ```
  cd ~/app
  cp dotenv.sample .env.production
  ```
  
  You will need to enter values for all the keys under REQUIRED except SYMMETRIC_ENCRYPTION_KEY, DEVISE_SECRET_KEY, COOKIES_SECRET_BASE and ONAPP_ROLE which are explained in the next step.
  
  Make sure to update Postgres credentials. For example:
  
  ```
  # Postgres credentials
  DB_NAME=cloudnet
  DB_USER=cloudnet
  DB_PASSWD='postgres-password'
  DB_HOST=localhost
  DB_PORT=5432
  ```
  
  Next, bundle install required gems and source the env file.

  ```
  cd ~/app
  bundle install --without development test
  source .env.production
  ```
  
  Next, create role at OnApp
  
  ```
  bundle exec rake create_onapp_role
  ```
  
  Copy the ID that is generated to ONAPP_ROLE setting in .env.production
  
  Generate value for SYMMETRIC_ENCRYPTION_KEY and update env file with the same (without line breaks)
  
  `rails generate symmetric_encryption:new_keys production`
  
  Likewise, run the following command to generate values for DEVISE_SECRET_KEY and COOKIES_SECRET_BASE each (you need to run twice for each)
  
  `bundle exec rake secret`
  
  Next, load database schema, seed the application and finally precompile the assets.
  
  ```
  bundle exec rake db:schema:load
  bundle exec rake db:seed
  bundle exec rake assets:precompile
  ```
  
  Finally, install crontab with the following command
  
  `bundle exec whenever -w`
  
10. Configure sidekiq.service on systemd

  ```
  cd /tmp
  curl -O https://gist.githubusercontent.com/hackedunit/79b9c52b3a0cb6e0f7b41db907330c92/raw/a36a1fafd8c5f451492093407c69da7117867ff8/sidekiq.service
  sudo cp sidekiq.service /etc/systemd/system/
  sudo systemctl start sidekiq
  sudo systemctl enable sidekiq
  ```

11. Install and configure Puma

  ```
  cd ~/app
  curl -o config/puma.rb https://gist.githubusercontent.com/hackedunit/49ade312dac9eac8403df5a37635e4ba/raw/158c77ac5375af01054ba6765004a840bcce2b1a/puma.rb
  mkdir -p shared/pids shared/sockets shared/log
  ```

12. Configure systemd to start Puma on boot

  ```
  cd /tmp
  curl -O https://gist.githubusercontent.com/hackedunit/13b070283dbee0d88139ed455fd6d32d/raw/763bd13cafc979ca26d92af4d39aa94400a5dc39/puma.service
  sudo cp puma.service /etc/systemd/system/
  sudo systemctl start puma
  sudo systemctl enable puma
  ```

13. Copy SSL cert files to certs/ directory

14. Install and configure nginx for reverse proxying requests to the Puma app server.

  ```
  sudo apt-get install nginx
  cd /tmp
  curl -O https://gist.githubusercontent.com/hackedunit/e7f41bd443c1966809a3577a3687de66/raw/950c3bf679e182cdb7643d2d7e4a18203be2558e/cloudnet
  sudo cp cloudnet /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/cloudnet /etc/nginx/sites-enabled/cloudnet
  ```
  
  Update cloudnet file with the domain name you intend to use. The sample file uses 'cloudnet.com', so change everywhere cloudnet.com is specified.
  
  Next, restart nginx.
  
  `sudo service nginx restart`
  
  The app should now be up and running on the HTTPS port on the servers IP address. By default, an admin user is created with the following login.

  email: 'admin@cloud.net'
  pass: 'adminpassword'
