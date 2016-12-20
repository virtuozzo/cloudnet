This is a quick step-by-step guide to install Cloud.net on a server using Docker.

**Minimum requirements**

* A server running Ubuntu 14.04 LTS with at least 2GB of RAM.
* Onapp control panel with required permissions
* SMTP and few other third party logins

**Installation**

1. Install Docker and Docker Compose

  Please follow the instructions on the official Docker website to install Docker and Docker Compose on the server. 

  > https://docs.docker.com/engine/installation/ubuntulinux/
  > https://docs.docker.com/compose/install/

2. Clone the Cloud.net Github repo

  `$ git clone https://github.com/OnApp/cloudnet.git`

3. You will find self signed SSL certificates inside certs/ directory. Replace these with the proper SSL certificates with the same file name and location. These certificates are later mounted as a volume to the container running nginx.
  
4. Almost all of the required and third party logins and keys are read from .env.docker file. Make a copy of the sample environment file.

  `$ cp dotenv.sample .env.docker`
  
  Values for keys under PRE-CONFIGURED can be left as such unless you have made changes to how docker has been composed. You will need to enter values for all the keys under REQUIRED except SYMMETRIC_ENCRYPTION_KEY, DEVISE_SECRET_KEY, COOKIES_SECRET_BASE and ONAPP_ROLE which are explained in the next step.
    
5. Temporarily set `RAILS_ENV=test` under 'Environments' section in .env.docker and run the following commands

  ONAPP_ROLE is the OnApp user role that grants restricted permissions to Cloud.net users. Run the following command to create it.

  `$ docker-compose run --no-deps --rm cloudnet-app rake create_onapp_role`

  Copy the ID that is generated to ONAPP_ROLE setting in .env.docker

  `$ docker-compose run --no-deps --rm cloudnet-app rails generate symmetric_encryption:new_keys production`

  Copy the generated value for SYMMETRIC_ENCRYPTION_KEY in .env.docker (without the line-breaks)

  Likewise, run the following command to generate values for DEVISE_SECRET_KEY and COOKIES_SECRET_BASE each:

  `$ docker-compose run --no-deps --rm cloudnet-app rake secret`

  Now set value of RAILS_ENV env variable back to 'production' in .env.docker

6. Run the following commands to create and setup the database

  `$ docker-compose run --rm cloudnet-app rake db:create RAILS_ENV=production`

  `$ docker-compose run --rm cloudnet-app rake db:schema:load RAILS_ENV=production`

  `$ docker-compose run --rm cloudnet-app rake db:seed RAILS_ENV=production`
 
7. Finally, you can run the containers with the following command:

  `$ docker-compose up -d`
  
The app should now be up and running on the HTTPS port on the servers IP address. By default, an admin user is created with the following login.

email: 'admin@cloud.net'
pass: 'adminpassword'

There will be only one app container running at this point. You can add more app containers as required by running `$ docker-compose scale cloudnet-app=2` which will bring up another app container.

To check the status of the containers, run `$ docker-compose ps`

**Updating**

Pull latest changes from Github repo:

`$ git pull origin`

Check for any new or updated entries in dotenv.sample file and add or make changes as necessary to your .env.docker environment file. It is important that your .env.docker file contains all entries from the sample env file.

Pull the updated image from Docker Hub:

`$ docker pull onapp/cloudnet`

Run any pending migrations:

`$ docker-compose run --rm cloudnet-app rake db:migrate RAILS_ENV=production`

Run `$ docker-compose ps` and note the current container names. Typically, they should be cloudnet_cloudnet-app_1 and cloudnet_cloudnet-app_2 assuming you scaled to two app containers.

Now, scale up another 2 (or more, as much as you need) app containers.

`$ docker-compose scale cloudnet-app=4`

This will start two new containers with the updated image, cloudnet_cloudnet-app_3 and cloudnet_cloudnet-app_4. Wait for few minutes until the new containers have started and is ready to serve requests. We now need to stop and remove the older containers running on the older image.

`$ docker stop cloudnet_cloudnet-app_1`

`$ docker stop cloudnet_cloudnet-app_2`

At this point, you will have two new containers based on the newer image. If there was a problem and you would like to roll-back to the older containers, you could simply start the stopped containers and stop the newer ones.

Once you have made sure everything is working correctly, you may remove the older containers.

`$ docker-compose rm cloudnet-app`

Re-create cron and worker containers from the updated image.

`$ docker-compose up -d cloudnet-cron`

`$ docker-compose up -d cloudnet-worker`
