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
  
NB. You will need about 4GB to run all containers on a single machine.

**Building/retrieving the Cloud.net Docker image**    
First make sure you have the repo with:
`git clone https://github.com/OnApp/cloudnet`

For VMWare you will need the `vmware-lab` branch, so `git checkout vmware-lab` inside the repo.

Then build the image with: `docker build -t cloudnet .`

**Running the Docker containers**    
First you will need to populate your environment file with connection details to your OnApp
control panel. The only required values that *must* be added are marked with '[REQUIRED]' at the top of the environment file.
Ensure it is named `.env.docker` and placed in the root of the cloned cloud.net repo folder.

Inside the cloud.net repo run `docker-compose up`

If the above command doesn't exit, then cloud.net should be up and running. The `docker-compose up` command
is now a live log of all cloud.net's various logs.

Then create the database and structure with:

`docker exec -it cloudnet_cloudnet-web_1 rake db:create`    
`docker exec -it cloudnet_cloudnet-web_1 rake db:schema:load`    
`docker exec -it cloudnet_cloudnet-web_1 rake db:seed`    

**Accessing cloud.net**    
By default cloud.net will be accessible via: https://localhost

Note that the web server is set to use HTTPS and that default self-signed certificates have been provided for localhost domains.
If you need to access cloud.net from another domain, you can recreate the certificates using this guide: https://gist.github.com/tadast/9932075
Ensure the certificates are named `server.key` and `server.crt`, and are placed in the root of the cloud.net repo.

To login, goto: https://localhost/users/sign_in    
email: 'admin@cloud.net'    
pass: 'adminpassword'    

**Misc**    
To run arbitrary commands, eg; rails console:

`docker exec -it cloudnet_cloudnet-web_1 rails console`

##TODO
Document scaling with Docker using a [Swarm](http://docs.docker.com/swarm/) and a load balancer.

#CONTRIBUTING
Pull Requests welcome
