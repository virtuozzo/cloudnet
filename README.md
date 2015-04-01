[ ![Codeship Status for OnApp/cloudnet](https://codeship.com/projects/6e11e150-aeee-0132-a36c-2a23891ee2d0/status?branch=master)](https://codeship.com/projects/69018)

#Control Panel for Cloud.net

[Cloud.net](https://cloud.net) is an end user interface to [OnApp](http://onapp.com/)'s cloud provisioning platform. Cloud.net is equivalent to other well known hosting providers such as [Digital Ocean](https://www.digitalocean.com/) or [Linode](https://www.linode.com/).

You will find this repository useful if you have your own installation of OnApp and want to offer paid cloud hosting through a more traditional interface.

##Installation

The recommended installation method is with [Docker](http://www.docker.com). Although traditional
methods should also work, see `Dockerfile` and this README as a guide.

**Dependencies**   
Cloud.net has various dependencies;
  * [OnApp](http://onapp.com/platform/pricing-packages/): cloud provision
  * [Postgres](https://wiki.postgresql.org/wiki/Detailed_installation_guides): main database
  * [Redis](http://redis.io/): message queuing
  * [Memcache](http://memcached.org/): caching
  * [Zendesk API](https://developer.zendesk.com/rest_api/docs/core/introduction#content): customer support
  * [Maxmind API](http://dev.maxmind.com/): credit card fraud detection
  * [Segment API](https://segment.com/): custom analytics
  * [Sentry](https://getsentry.com/welcome/): exception logging
  * [Stripe API](https://stripe.com): payment gateway
  * [500PX API](http://developers.500px.com/): photo library
  * [Mapbox API](https://www.mapbox.com/developers/api/): displaying maps

You will need to either install or register API keys for all these dependencies.

**Building/retrieving the Cloud.net Docker image**    
You can either pull the latest image from the Docker registry with `docker pull Onapp/cloudnet`

Or build the image yourself. First make sure you have the repo with
`git clone https://github.com/OnApp/cloudnet` then in the root of the repo run
`docker build -t cloudnet .`

**Initial config**    
Firstly you will need to populate the `dotenv.sample` file and rename it to `.env`

Then create the database structure with `docker run --env-file=.env --rm cloudnet rake db:schema:load`.

And finally seed the database with `docker run --env-file=.env --rm cloudnet rake db:seed`. This will 
add the available providers from your OnApp installation and an initial admin user with 
username 'admin' and password 'password'.

You will then need to change the admin password and fill out the extra details for the providers
that your installation is offering. For instance each provider needs a price per disk/cpu/memory.
You can edit these details through the admin interface at `/admin/locations`.

**Running the Docker containers**    
You will need at least 2 containers:

  * Web container:
```
docker run \
  --env-file=.env \
  -p 80:3443 \
  -p 443:3443 \
  --restart=always \
  --name cloudnet-web \
  cloudnet foreman run web
```
  * Worker container:
```
docker run \
  --env-file=.env \
  --restart=always \
  --name cloudnet-worker \
  cloudnet foreman run sidekiq --logfile /dev/stdout
```

##TODO
Document scaling with Docker using a [Swarm](http://docs.docker.com/swarm/) and a load balancer.

#CONTRIBUTING
Pull Requests welcome

#LICENSE
TBC
