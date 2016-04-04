[ ![Codeship Status for OnApp/cloudnet](https://codeship.com/projects/6e11e150-aeee-0132-a36c-2a23891ee2d0/status?branch=master)](https://codeship.com/projects/69018)

#Control Panel for Cloud.net

[Cloud.net](https://cloud.net) is an end user interface to [OnApp](http://onapp.com/)'s cloud provisioning platform.

Cloud.net is the first truly transparent marketplace for global cloud infrastructure. You can deploy servers on clouds all over the world, get independently-verified data about price, performance and uptime, and manage everything through one control panel.

You will find this repository useful if you have your own installation of OnApp and want to offer paid cloud hosting through a more traditional interface.

##Installation

**Dependencies**    
Before installing you will need the following:
  * [OnApp](http://onapp.com/platform/pricing-packages/)
  * [Docker Compose](https://docs.docker.com/compose/install/)
  * Optional: an SMTP mail server, eg [Sendgrid](https://sendgrid.com/), [Mandrill](https://www.mandrill.com/), etc.
  
NB. You will need about 2GB to run all containers on a single machine.

**Building/retrieving the Cloud.net Docker image**    
First make sure you have the repo with:
`git clone https://github.com/OnApp/cloudnet`

You can either pull the latest image from the Docker registry with `docker pull onapp/cloudnet`

Or build the image yourself: `docker build -t onapp/cloudnet .`

You will find self signed SSL certificates inside certs/ directory. (Optional) If you are deploying this to production, replace these with the proper SSL certificates with the same file name and location. These certificates are later mounted as a volume to the container running nginx.

**Running the Docker containers**    
You will need to populate your environment file with connection details to your OnApp control panel and other third party services. A sample dotenv.sample is provided. Ensure it is renamed to `.env.docker` and placed in the root of the cloned cloud.net repo folder.

You will need to enter values for all the keys under REQUIRED. The keys under PRE-CONFIGURED can be left as such unless you have made changes to how docker has been composed. 

ONAPP_ROLE is the OnApp user role that grants restricted permissions to Cloud.net users. Run the command in the next step to create it.

Temporarily add `RAILS_ENV=test` at top of .env.docker and run the following commands:

`$ docker-compose run --no-deps --rm cloudnet-app rake create_onapp_role`

The ID will need to be added to the ONAPP_ROLE setting in .env.docker

`$ docker-compose run --no-deps --rm cloudnet-app rails generate symmetric_encryption:new_keys production`

Copy the generated key as value for SYMMETRIC_ENCRYPTION_KEY in .env.docker

Likewise, run the following command to generate values for DEVISE_SECRET_KEY and COOKIES_SECRET_BASE each:

`$ docker-compose run --no-deps --rm cloudnet-app rake secret`

Now remove RAILS_ENV=test from .env.docker

Run the following commands to create and setup the database

`$ docker-compose run --rm cloudnet-app rake db:create RAILS_ENV=production`

`$ docker-compose run --rm cloudnet-app rake db:schema:load RAILS_ENV=production`

`$ docker-compose run --rm cloudnet-app rake db:seed RAILS_ENV=production`

Finally, you can run the containers with the following command:

`$ docker-compose up -d`

The app should now be up and running on the HTTPS port on the servers IP address. There will be only one app container running by default. You can add more app containers as required by running `$ docker-compose scale cloudnet-app=2` which will bring up another app container and nginx will be configured automatically to load balance to the new app containers.

**Accessing cloud.net**    
By default cloud.net will be accessible via: https://localhost

Note that the web server is set to use HTTPS and that default self-signed certificates have been provided for localhost domains.
If you need to access cloud.net from another domain, you can recreate the certificates using this guide: https://gist.github.com/tadast/9932075

Ensure the certificates are named `server.key` and `server.crt`, and are placed in the certs/ directory of the cloud.net repo.

To login, goto: https://localhost/users/sign_in

email: 'admin@cloud.net'    
pass: 'adminpassword'

You will then need to change the admin password and fill out the extra details for the providers that your installation is offering. For instance each provider needs a price per disk/cpu/memory. You can edit these details through the admin interface at /admin/locations.

**Misc**    
To run arbitrary commands, eg; rails console:

`$ docker-compose run --rm cloudnet-app rails console production`

##Quick install
For a more easier step-by-step guide to installing and updating Cloud.net on a server with zero downtime see the [install guide](INSTALL.md)

##TODO
Document scaling with Docker using a [Swarm](http://docs.docker.com/swarm/) and a load balancer.

##CONTRIBUTING
Pull Requests welcome
