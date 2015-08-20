[ ![Codeship Status for OnApp/cloudnet](https://codeship.com/projects/6e11e150-aeee-0132-a36c-2a23891ee2d0/status?branch=master)](https://codeship.com/projects/69018)

#Control Panel for Cloud.net

[Cloud.net](https://cloud.net) is an end user interface to [OnApp](http://onapp.com/)'s cloud provisioning platform.

Cloud.net is the first truly transparent marketplace for global cloud infrastructure. You can deploy servers on clouds all over the world, get independently-verified data about price, performance and uptime, and manage everything through one control panel.

You will find this repository useful if you have your own installation of OnApp and want to offer paid cloud hosting through a more traditional interface.

##Installation

The recommended installation method is with [Docker](http://www.docker.com). Although traditional
methods should also work, see `Dockerfile` and this README as a guide.

**Dependencies**    
Before installing you will need the following:
  * [OnApp](http://onapp.com/platform/pricing-packages/): cloud provision
  * [Postgres](https://wiki.postgresql.org/wiki/Detailed_installation_guides): main database
  * [Redis](http://redis.io/): message queuing
  * Optional: an SMTP mail server, eg [Sendgrid](https://sendgrid.com/), [Mandrill](https://www.mandrill.com/), etc.

**Building/retrieving the Cloud.net Docker image**    
First make sure you have the repo with:
`git clone https://github.com/OnApp/cloudnet`

For VMWare you will need the `vmware-lab` branch, so `git checkout vmware-lab`.

Then run `docker build -t cloudnet .`

**Initial config**    
Firstly you will need to populate your environment file, then name it `.env` and place
it in the project's root folder.

Then create the database and structure with:

`docker run --env-file=.env --rm cloudnet rake db:create`

`docker run --env-file=.env --rm cloudnet rake db:schema:load`

And finally seed the database with `docker run --env-file=.env --rm cloudnet rake db:seed`. This will add the available providers from your OnApp installation and an initial admin user with;    
email: 'admin@cloud.net' and password: 'adminpassword'.

**Running the Docker containers**    
You will need at least 2 containers:

Note that the web server is set to use HTTPS, default self-signed certificates have been provided for localhost domains.
Certificates are the mounted via the `-v` (mount argument) as shown in the `docker run` command below. The certificates must be named;
`server.key` and `server.crt`. General guide to self-signing can be found here: https://gist.github.com/tadast/9932075

  * Web container:
```
docker run \
  --env-file=.env \
  -p 443:3443 \
  -v $(pwd):/mnt/certs \
  --restart=always \
  --name cloudnet-web \
  --detach
  cloudnet foreman run web
```

  * Worker container:
```
docker run \
  --env-file=.env \
  --restart=always \
  --name cloudnet-worker \
  --detach \
  cloudnet foreman run sidekiq --logfile /dev/stdout
```

##MISC
To get a rails console:

`docker run -it --env-file=.env.vmware-lab --rm cloudnet rails console`

##TODO
Document scaling with Docker using a [Swarm](http://docs.docker.com/swarm/) and a load balancer.

#CONTRIBUTING
Pull Requests welcome
