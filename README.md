# Docker and Kubernetes
https://www.udemy.com/course/docker-kubernetes-the-practical-guide

### What is Docker? And Why?
Docker is a container technology. It is a tool for creating and managing containers.
Containers are standardized units of software. It includes a package of code and dependencies to run the code.
The same container will always give the same result. All behaviour is baked into the container.
Like a picnic basket the container contains everything you need to run the application.

### Why Containers?
Why do we want independent, standardized "application packages"?
This code needs 14.13.0 to work:

```js
import express from 'express';
import connnectToDatabase from './helpers.mjs';

const app = express();
app.get('/', (req, res) => {
    res.send('<h2>Hi there!</h2>');
});

await connectToDatabase();
app.listen(3000);
```
This code would break on earlier versions. Having the exact same development environment as production can help a lot.

### Docker build
Run dockerfiles with:
```bash
docker build .
```
This gets the node environment from DockerHub and sets up an image which is prepared to be started as a container.
![image](https://user-images.githubusercontent.com/27693622/230169853-fc346676-23f0-4904-b192-b1a3510a7dd7.png)

#### Outline
- foundation sections: lay out the basics for docker
  - images & containers - how build own images
  - data & volumes - ensure data persists
  - containers & networking - multiple containers can talk to each other
- real life
  - multi-container projects
  - using Docker-compose
  - "Utility Containers"
  - Deploy Containers with AWS
- Kubernetes
  - Introduction & Basics
  - Data and Volumes
  - Networking
  - Deploying a Kubernetes Cluster

#### Docker Images and Containers: The Core Building Blocks
- working with Images and Containers
- How Images are related to containers
- Pre-build and Custom Images
- Create, run and Manage Docker Containers

#### Running node in Docker
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes$ docker run -it node
Welcome to Node.js v19.8.1.
Type ".help" for more information.
> 1 + 1
2
```
The node runtime is exposed us with the command '-it'.
Images contain the setup, Containers are the running version of the image.

Typically we would build up on the node image and then add the application code to the base image to execute the code
within the base image. We would then write our own Dockerfile based on the image.

We now add a Dockerfile for building the nodejs-app-starting-setup:
```dockerfile
FROM node

WORKDIR /app

COPY . /app

RUN npm install

EXPOSE 80

CMD ["node", "server.js"]
```
We build the image with:
```bash
docker build -t nodejs-app . 
```

This now shows an image:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/first-demo-starting-setup$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
nodejs-app   latest    df28934e6946   3 days ago    916MB
```

We need to expose the port in order to view the application:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/nodejs-app-starting-setup$ docker run -p 3000:80 7fa
```
![image](https://user-images.githubusercontent.com/27693622/230773820-d05619f7-ad4f-4459-a040-4a878e5d255e.png)


### Images are read only
In the Dockerfile this line:
```dockerfile
COPY . /app
```
makes a copy of the code into the image. Images are locked and finished after we build the image.

![image](https://user-images.githubusercontent.com/27693622/230774755-90fd19fd-a069-440d-ac7a-ab69ab2b8caa.png)

The layer based architecture allows Docker to use caches to rebuild images. It will only rebuild a layer if it detects
that code has changed on the source code.

This version of our Dockerfile will ensure that npm install is not run everytime code has changed:
```dockerfile
FROM node

WORKDIR /app

COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```

![image](https://user-images.githubusercontent.com/27693622/230775757-cb3d10ec-7578-496c-a4f9-8f25cd026e9d.png)

The containers run independently of the image and can be made to run in parallel. The image is a blueprint for the
containers which then are running instances with read and write access. This allows multiple containers to be based
on the same image without interfering with each other. Containers are separated from each other and have no shared
date or state by default. A container is an isolated unit of software based on an image. A container is a running instance
of the image. Each instruction to create an image creates a cacheable layer - the layers help with image re-building and
sharing.

### Managing Images and Containers

![image](https://user-images.githubusercontent.com/27693622/230777233-d25ad34e-6002-4801-94a0-65dc10fe519f.png)

We can also attach to already-running containers with:
```bash
docker attach <IMAGE ID>
```
We can also view the logs with:
```bash
 docker logs -f <IMAGE ID>
```
We can also attach to console output with the following:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/python-app-starting-setup$ docker start -ai deb
Please enter the min number: 10
Please enter the max number: 23
11
```

You can run:
```bash
docker container prune
```
to delete all stopped containers. To delete all unused images run:
```bash
docker image prune 
```
To automatically remove containers when they exit we can run:
```bash
docker run -p 3000:80 -d --rm <IMAGE ID>
```

We can also inspect an image with:
```bash
docker image inspect <IMAGE ID>
```

To look at and change docker containers:
```bash
docker 
```

We can copy local files to running containers with:
```bash
docker cp dummy/. hungry_kilby:/test
```
This is useful for adding files to running containers. This might be useful for configuration changes.
Copying files out of a container can also be useful for log files.

![image](https://user-images.githubusercontent.com/27693622/230872646-d82e5b91-8d42-4dd7-91ec-7805adec5206.png)

To name a container you can run:
```bash
docker run --name <NAME> -it --rm <IMAGE_ID>
```

We can also run:
```bash
docker run --name server -p 3000:3000 --rm 53b
```

You can also rename images:

```bash
docker tag node-demo:latest academind/node-hello-world
```

You can also push images that you have tagged:
```bash
docker push tomspencerlondon/node-hello-world:1
```

#### Managing Data and Working with Volumes

We can store container data that we want to persist in volumes. 
We have a node application and we will store data in temp and feedback:
```javascript
app.post('/create', async (req, res) => {
  const title = req.body.title;
  const content = req.body.text;

  const adjTitle = title.toLowerCase();

  const tempFilePath = path.join(__dirname, 'temp', adjTitle + '.txt');
  const finalFilePath = path.join(__dirname, 'feedback', adjTitle + '.txt');

  await fs.writeFile(tempFilePath, content);
  exists(finalFilePath, async (exists) => {
    if (exists) {
      res.redirect('/exists');
    } else {
      await fs.rename(tempFilePath, finalFilePath);
      res.redirect('/');
    }
  });
});
```

The temp folder stores files before copying to feedback. The temp file will be temporary storage. We will persist data in the
feedback folder.

We then add a Dockerfile:
```dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "server.js"]
```

We build and run the app:
```bash
docker build -t feedback-node .
docker run -p 3000:80 -d --name feedback-app --rm feedback-node
```

Files saved at the moment only exist in the running container.
If we delete the container and run another container, the file no longer exists.
However, if we start the original container again the data still exists.

![image](https://user-images.githubusercontent.com/27693622/230774755-90fd19fd-a069-440d-ac7a-ab69ab2b8caa.png)

We can use volumes to persist data between containers on the host machine which are mounted into containers.
This creates a connection between the host machine folder and a folder in the container. Changes in either folder are
reflected on the other folder. Volumes are persisted if a container shuts down. The volume will not be removed when a container is
removed. Containers can read and write data to volumes.

To save volumes we can add a line in our Dockerfile:
```dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

VOLUME ["/app/feedback"]

CMD ["node", "server.js"]
```
The ```VOLUME ["/app/feedback"]``` instruction assigns where we will listen for changes in the container to persist
to our host files.

We can now build and run the image:
```bash
docker build -t feedback-node:volumes .
docker run -d -p 3000:80 --rm --name feedback-app feedback-node:volumes
```

We can view the logs with:
```bash
docker logs feedback-app
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(Use `node --trace-warnings ...` to show where the warning was created)
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 1)
(node:1) [DEP0018] DeprecationWarning: Unhandled promise rejections are deprecated. In the future, promise rejections that are not handled will terminate the Node.js process with a non-zero exit code.
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 2)
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 3)
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 4)
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 5)
(node:1) UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/awesome.txt' -> '/app/feedback/awesome.txt'
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 6)
```

We now change the source code:
```javascript

app.post('/create', async (req, res) => {
  const title = req.body.title;
  const content = req.body.text;

  const adjTitle = title.toLowerCase();

  const tempFilePath = path.join(__dirname, 'temp', adjTitle + '.txt');
  const finalFilePath = path.join(__dirname, 'feedback', adjTitle + '.txt');

  await fs.writeFile(tempFilePath, content);
  exists(finalFilePath, async (exists) => {
    if (exists) {
      res.redirect('/exists');
    } else {
      await fs.copyFile(tempFilePath, finalFilePath);
      await fs.unlink(tempFilePath);
      res.redirect('/');
    }
  });
});

app.listen(80);
```

We can now rebuild and run the image:
```bash
docker build -t feedback-node:volumes .
docker run -d -p 3000:80 --rm --name feedback-app feedback-node:volumes
```
There are two types of external Data Storage: volumes (managed by docker) and bind mounts (managed by us).
We can use named volumes to ensure that the volume persists after a docker container has been shut down:

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes
```
The named volume will not be deleted by Docker when the container is shut down. Named volumes are not attached to containers. The
data is now persisted with the help of named volumes.

### Bind Mounts
Bind mounts can help us with changes in the source code so that they are reflected in the running container.
Bind mounts are similar to volumes but the path is set on our internal machine where to keep the volumes.
Bind mounts are great for persistent, editable data.

There are also shortcuts for bind mounts:
```bash
$(pwd):/app
```
Windows:
```bash
"%cd%":/app
```

We also need an anonymous volume for storing node_modules:

```bash
docker run -d -p 3000:80 --name feedback-app -v feedback:/app/feedback -v "/home/tom/Projects/Docker-And-Kubernetes/data-volumes-01-starting-setup:/app" -v /app/node_modules feedback:volume
```

Here ```-v /app/node_modules``` ensures that the node_modules folder persists.


### Volumes and bind mounts summary
- docker run -v /app/data (anonymous volume)
- docker run -v data:/app/data (named volume)
- docker run -v /path/to/code:/app/code (bind mount)

Anonymous volumes are created specifically for a container. They do not survive --rm and cannot be used to share across containers.
Anonymous volumes are useful for locking in data which is already in a container and which you don't want to be overwritten.
They still create a counterpart on the host machine.

Named volumes are created by -v with name:/PATH. They are not tied to specific containers and survive shutdown and restart of the container.
These can be used to share across containers and shutdowns and removals.

Bind mounts are given a place to save data on the host machine. They also survive shutdown / restart of the docker container.

You can also ensure that the container is not able to write files with ro:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/data-volumes-01-starting-setup$ docker run -d -p 3000:80 --name feedback-app -v feedback:/app/feedback -v "/home/tom/Projects/Docker
-And-Kubernetes/data-volumes-01-starting-setup:/app:ro" -v /app/node_modules feedback:volume
```
This ensures that docker will not be able to write to folder and host files.

You can delete all dangling volumes with:
```bash
    docker volume rm -f ${docker volume ls -f dangling=true -q}
```

We can use .dockerignore to specify which folders to ignore when we run
the Dockerfile, in particular the ```COPY . .``` command.

Docker supports build-time ARGs and runtime ENV variables.
- ARG (set on image build) via --build-arg
- set via ENV in Dockerfile or via --env on docker run

For instance we can expect a port environment variable:
```javascript
app.listen(process.env.PORT);
```

We can then add the environment variable:

```dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

ENV PORT 80

EXPOSE $PORT

# VOLUME ["/app/node_modules"]

CMD ["npm", "start"]
```

We can then set the port in our docker run command:
```bash
docker run -d -p 3000:8000 --env PORT=8000 --name feedback-app -v feedback:/app/feedback -v "/home/tom/Projects/Docker-And-Kubernetes/data-volumes-01-starting-setup:/app:ro" -v /app/temp -v /app/node_modules feedback:env
```

You can also specify environment variables via ```--env-file```:
```bash
docker run -d -p 3000:8000 --env-file ./.env --name feedback-app -v feedback:/app/feedback -v "/home/tom/Projects/Docker-And-Kubernetes/data-volumes-01-starting-setup:/app:ro" -v /app/temp -v /app/node_modules feedback:env
```
The values would then be run from the file. We can add an ARG with the following:
```dockerfile
FROM node:14


WORKDIR /app

COPY package.json .

RUN npm install

ARG DEFAULT_PORT=80

COPY . .

ENV PORT $DEFAULT_PORT

EXPOSE $PORT

# VOLUME ["/app/node_modules"]

CMD ["npm", "start"]
```

We can then set a default port via ARGs:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/data-volumes-01-starting-setup$ docker build -t feedback:dev --build-arg DEFAULT_PORT=8000 .

```

### Networking: Cross-Container Communication
- how to use networks inside containers
- how to connect multiple containers
- connect Container to other ports on your machine
- connect to web from container
- containers and external networks
- connecting containers with networks

#### Connecting to external sites

![image](https://user-images.githubusercontent.com/27693622/230928391-ab153412-9954-4619-a2c7-ad95803bef6a.png)

In our example application we are using axios to make a get request to the Star Wars API:
```javascript


app.get('/movies', async (req, res) => {
  try {
    const response = await axios.get('https://swapi.dev/api/films');
    res.status(200).json({ movies: response.data });
  } catch (error) {
    res.status(500).json({ message: 'Something went wrong.' });
  }
});


app.get('/people', async (req, res) => {
  try {
    const response = await axios.get('https://swapi.dev/api/people');
    res.status(200).json({ people: response.data });
  } catch (error) {
    res.status(500).json({ message: 'Something went wrong.' });
  }
});
```

The Star Wars API is an outside application which means we will have http communication between our container
and the API.

### Container to LocalHost machine communication

We might also want to communicate with our local host machine:
![image](https://user-images.githubusercontent.com/27693622/230929504-ead24d66-25ae-4dc0-b3a6-6b43f80263c9.png)

Here we are also connecting to our local Mongodb instance:
```javascript
mongoose.connect(
  'mongodb://localhost:27017/swfavorites',
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```
We are using this instance to store data. This means that we also need to allow a connection to localhost connection
requests.

### Container to Container
Alongside connections to the web and the host containers may also need to connect to other containers.

![image](https://user-images.githubusercontent.com/27693622/231071713-3caf5bde-c469-41d2-8b33-ab544f79c482.png)

Connecting to mongodb from our container fails:
```bash
docker run --name favorites --rm -p 3000:3000 favorites-node
```
The connection to the outside WWW works. Sending requests to the web works. The connection to the server on our localhost
is not working.
Instead of localhost we need to use host.docker.internal to communicate with the host:
```javascript
mongoose.connect(
  'mongodb://host.docker.internal:27017/swfavorites',
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

This works out of the box with Apple mac but on Linux we need to add an extra configuration with our run command:
```bash
docker run --add-host=host.docker.internal:host-gateway --name favorites --rm -p 3000:3000 favorites-node
```
This article was quite useful:
https://medium.com/@TimvanBaarsen/how-to-connect-to-the-docker-host-from-inside-a-docker-container-112b4c71bc66
![image](https://user-images.githubusercontent.com/27693622/231079512-15df9661-48f3-4fc7-a253-16364803d6f6.png)

To kill my linux mongo process I use:
```bash
ps -edaf | grep mongo | grep -v grep
root      577139       1  0 Apr10 ?        00:05:32 /snap/mongo44-configurable/30/usr/bin/mongod -f ./mongodb.conf

tom@tom-ubuntu:~$ kill 577139

```

To restart I would use:
```bash
tom@tom-ubuntu:~$ systemctl start mongodb.service
tom@tom-ubuntu:~$ mongosh
```

#### Container to Container Communication
We can now set up our own mongodb container:
```bash
docker run -d --name mongodb mongo
```

We can run docker inspect on this container:
```bash
 docker container inspect mongodb
```
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/assignment-problem/python-app$ docker container inspect mongodb
[
    {
        "Id": "cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7",
        "Created": "2023-04-11T07:41:20.702642664Z",
        "Path": "docker-entrypoint.sh",
        "Args": [
            "mongod"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 636701,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2023-04-11T07:41:21.106385264Z",
            "FinishedAt": "0001-01-01T00:00:00Z"
        },
        "Image": "sha256:9a5e0d0cf6dea27fa96b889dc4687c317f3ff99f582083f2503433d534dfbba3",
        "ResolvConfPath": "/var/lib/docker/containers/cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7/hostname",
        "HostsPath": "/var/lib/docker/containers/cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7/hosts",
        "LogPath": "/var/lib/docker/containers/cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7/cc158e92f413a5204b88c9fa3f91f7b64520bbde78981a896c69aed886b6daf7-json.log",
        "Name": "/mongodb",
        "RestartCount": 0,
        "Driver": "overlay2",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "docker-default",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": null,
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {}
            },
            "NetworkMode": "default",
            "PortBindings": {},
            "RestartPolicy": {
                "Name": "no",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                7,
                186
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": null,
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": {
                "LowerDir": "/var/lib/docker/overlay2/37ae49740da59c46330f65cca2bae421464a26b8149adf7f377dd7488a7725ff-init/diff:/var/lib/docker/overlay2/21c94ca3a37970ed208ff53802d06212df8997b49d97ad95393b103e9dc62225/diff:/var/lib/docker/overlay2/57d06f65a5a31ad60116a2e756c782adaf8eca7e753df94529c3b674d97b0bed/diff:/var/lib/docker/overlay2/299904a31b191907fbbefdf6b8ac3063678c1c87d4bb8bb1ca47f2b4fa30b66d/diff:/var/lib/docker/overlay2/57bfb3af2467e04434bca071b9482316ce953ed386d24fdb41e937518f8df927/diff:/var/lib/docker/overlay2/f071b2453b15ec3a8563843a1752232e79e8382b6e6a0805889cc4de0a929812/diff:/var/lib/docker/overlay2/bbee005e09c5651edf804327e684b7417d1edded8871e387872fa2372548f73e/diff:/var/lib/docker/overlay2/0a2aa49b363b51c8f2c6407e0b7b8247693cb6ea1328356d472a6e2680ccebf8/diff:/var/lib/docker/overlay2/4b860531fedfe9b4dc9739a8ac9c596e2427738945e3977e0ca130b33a12c293/diff:/var/lib/docker/overlay2/91356fe1ada980294315d2a034870673e4da948007658ab79986640b787b6338/diff",
                "MergedDir": "/var/lib/docker/overlay2/37ae49740da59c46330f65cca2bae421464a26b8149adf7f377dd7488a7725ff/merged",
                "UpperDir": "/var/lib/docker/overlay2/37ae49740da59c46330f65cca2bae421464a26b8149adf7f377dd7488a7725ff/diff",
                "WorkDir": "/var/lib/docker/overlay2/37ae49740da59c46330f65cca2bae421464a26b8149adf7f377dd7488a7725ff/work"
            },
            "Name": "overlay2"
        },
        "Mounts": [
            {
                "Type": "volume",
                "Name": "d3896d83f9b430ebf3c5797c87253b11b17fdebd5b0d62f6570403b4f7a6e0ee",
                "Source": "/var/lib/docker/volumes/d3896d83f9b430ebf3c5797c87253b11b17fdebd5b0d62f6570403b4f7a6e0ee/_data",
                "Destination": "/data/configdb",
                "Driver": "local",
                "Mode": "",
                "RW": true,
                "Propagation": ""
            },
            {
                "Type": "volume",
                "Name": "9de44e9d37f1dc834d08c287d12373488d979ffce405317004110d9b51760adb",
                "Source": "/var/lib/docker/volumes/9de44e9d37f1dc834d08c287d12373488d979ffce405317004110d9b51760adb/_data",
                "Destination": "/data/db",
                "Driver": "local",
                "Mode": "",
                "RW": true,
                "Propagation": ""
            }
        ],
        "Config": {
            "Hostname": "cc158e92f413",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "27017/tcp": {}
            },
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "GOSU_VERSION=1.16",
                "JSYAML_VERSION=3.13.1",
                "MONGO_PACKAGE=mongodb-org",
                "MONGO_REPO=repo.mongodb.org",
                "MONGO_MAJOR=6.0",
                "MONGO_VERSION=6.0.5",
                "HOME=/data/db"
            ],
            "Cmd": [
                "mongod"
            ],
            "Image": "mongo",
            "Volumes": {
                "/data/configdb": {},
                "/data/db": {}
            },
            "WorkingDir": "",
            "Entrypoint": [
                "docker-entrypoint.sh"
            ],
            "OnBuild": null,
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "22.04"
            }
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "441a40d9de862616860771749efc5fb5e9d042d9534078be75d5bcc9c3abb8b4",
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "Ports": {
                "27017/tcp": null
            },
            "SandboxKey": "/var/run/docker/netns/441a40d9de86",
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "37eb934ae50f4196699052c8d0b6ce06c3c2c9f2fcb91bac045d4ac58a26f5c1",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "02:42:ac:11:00:02",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "NetworkID": "136c829bf8aca834b3f7d5f2818c907b41ca2da2acfff2e7a05a8f61536804ca",
                    "EndpointID": "37eb934ae50f4196699052c8d0b6ce06c3c2c9f2fcb91bac045d4ac58a26f5c1",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "MacAddress": "02:42:ac:11:00:02",
                    "DriverOpts": null
                }
            }
        }
    }
]

```

we can see the ip address:
```bash
"IPAddress": "172.17.0.2"
```

we can then use this address to connect to the mongodb container:
```javascript
mongoose.connect(
  'mongodb://172.17.0.2:27017/swfavorites',
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```
We then rebuild the image:

```bash
docker build -t favorites-node .
```
and run the container:
```bash
docker run --name favorites --rm -p 3000:3000 favorites-node
```
This is not so convenient as we have to look up the ip address and then build a new image. There is an easier way
to make multiple docker containers talk to each other. We can use Container networks:

![image](https://user-images.githubusercontent.com/27693622/231094021-bb3c1f13-91fd-41e7-a4af-13580b4d68b1.png)

We create a network:

```bash
docker network create favorites-net
```
We can now run the mongodb database container and connect to the network:
```bash
 docker run -d --name mongodb --network favorites-net mongo
```

We can now use the container name to connect to the mongodb container from our node application:
```bash
mongoose.connect(
  'mongodb://mongodb:27017/swfavorites',
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

We can now run the node application to connect to the same network:
```bash
docker run --name favorites --network favorites-net -d --rm -p 3000:3000 favorites
```

We can now post and get the favorite films from the node app:
![image](https://user-images.githubusercontent.com/27693622/232021829-0e96c1b6-b35a-4046-a36a-3fb44414edc0.png)

![image](https://user-images.githubusercontent.com/27693622/232021946-90f7e179-7299-40c4-8780-ee28cb84f54a.png)

This proves that the two containers can communicate using the built in network feature:
![image](https://user-images.githubusercontent.com/27693622/231079512-15df9661-48f3-4fc7-a253-16364803d6f6.png)

The containers can only talk to each other with a shared network. When we use a shared network it means that we don't
have to expose IP addresses because the containers can communicate on the shared network.

### Docker Network IP Resolving
we can use host.docker.internal to target the host machine and when we have containers in the same network
we can use the name of the container to direct traffic. Docker does not replace the sort code it simply
detects outgoing requests and resolves the IP for the requests. If a request is using the web or addresses within the
container docker doesn't need to do anything.

### Building Multi-container applications
We will now combine multiple services to one application and work with multiple containers.

![image](https://user-images.githubusercontent.com/27693622/232026077-6461260e-4a64-406e-a524-30ca12d8ed48.png)

The above is a common setup for a web application which includes a backend database with a front end application which brings
html to the screen and the frontend talks to the backend.

Next we stop our local mongo server:
```bash
systemctl stop mongodb.service
```
The above is the command for linux ubuntu. We then test that mongo is no longer running locally:
```bash
> mongosh
Current Mongosh Log ID: 643bb8f18cb210ce64ba9eb6
Connecting to:          mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+1.8.0
MongoNetworkError: connect ECONNREFUSED 127.0.0.1:27017
```

We then run the mongo container:
```bash
docker run --name mongodb --rm -d -p 27017:27017 mongo
```

I can see the container running:
```bash
 docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                                                  NAMES
920dd45443b3   mongo          "docker-entrypoint.s…"   8 seconds ago   Up 5 seconds   0.0.0.0:27017->27017/tcp, :::27017->27017/tcp          mongodb
```

We then run the multi-01-starting-setup backend:
```dockerfile
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3001

CMD ["node", "app.js"]
```

We then build the backend image:
```bash
docker build -t goals-node .
```

This fails to connect to mongodb. In the dockerised backend app we are still reaching for localhost.

We add the ip for localhost for docker:
```javascript
mongoose.connect(
        'mongodb://host.docker.internal:27017/course-goals',
        {
          useNewUrlParser: true,
          useUnifiedTopology: true,
        },
        (err) => {
          if (err) {
            console.error('FAILED TO CONNECT TO MONGODB');
            console.error(err);
          } else {
            console.log('CONNECTED TO MONGODB');
            app.listen(3001);
          }
        }
);
```
We should also remove our docker cache:
```bash
docker system prune -a
```
We then rebuild the image:
```bash
docker build -t goals-node .
```
We then rerun the container:
```bash
docker run --name goals-backend --add-host=host.docker.internal:host-gateway --rm goals-node
```
When running with linux we have to add:
```bash
--add-host=host.docker.internal:host-gateway
```
to expose host.docker.internal.

The front end still fails to connect to the docker backend:
![image](https://user-images.githubusercontent.com/27693622/232289778-6662bf24-daee-49eb-ba4e-aaaeec9461df.png)

We still have to expose the port:
```bash
 docker run --name goals-backend --add-host=host.docker.internal:host-gateway --rm -d -p 3001:3001 goals-node
```

We can now connect the front end:
```bash
npm run start

> docker-frontend@0.1.0 start
> react-scripts --openssl-legacy-provider start

(node:70396) [DEP0111] DeprecationWarning: Access to process.binding('http_parser') is deprecated.
(Use `node --trace-deprecation ...` to show where the warning was created)
Starting the development server...
Compiled successfully!

You can now view docker-frontend in the browser.

  Local:            http://localhost:3000/
  On Your Network:  http://192.168.1.116:3000/

Note that the development build is not optimized.
To create a production build, use npm run build.
```
And the error is gone:
![image](https://user-images.githubusercontent.com/27693622/232289864-f038f2bd-155b-4338-9fac-fa68bd4a7654.png)

We now want to setup the frontend on docker:

```dockerfile
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

We then build the application:
```bash
docker build -t goals-react .
```

and run the container:

```bash
 docker run --name goals-front-end --rm -d -p 3000:3000 -it goals-react
```

For react applications we have to add -it.

We have now added all building blocks to their own containers. 

We now want to put all the docker containers on the same network:
```bash

docker network create goals-net
```

We start the mongodb database with the above network:
```bash
docker run --name mongodb --rm -d --network goals-net mongo
```

and run the backend on the same network. We change the connection url to refer to the running
mongodb docker container:
```javascript
mongoose.connect(
  'mongodb://mongodb:27017/course-goals',
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error('FAILED TO CONNECT TO MONGODB');
      console.error(err);
    } else {
      console.log('CONNECTED TO MONGODB');
      app.listen(3001);
    }
  }
);

```
We then rebuild the image:
```bash
docker build -t goals-node .
```
and run docker with the correct network:
```bash
docker run --name goals-backend --rm -d --network goals-net goals-node
```

We then build the frontend image:
```bash
docker build -t goals-react .
```

We run the react container:
```bash
docker run --name goals-frontend --network goals-net --rm -p 3000:3000 -it goals-react
```
We still get an error:
![image](https://user-images.githubusercontent.com/27693622/232322276-325f0512-12ac-41e7-8d4a-4aa21e5de0ba.png)

The code is running App.js in the browser not on the server. We can't use the container names.

We don't use the network and change the endpoints to localhost:
```bash
docker run --name goals-frontend --rm -p 3000:3000 -it goals-react
```
We now have to stop the goals-backend container. We then restart the backend with port 3001 exposed:

```bash
docker run --name goals-backend --rm -d -p 3001:3001 --network goals-net --rm goals-node
```
Everything is now working. We now have more to add:

![image](https://user-images.githubusercontent.com/27693622/232322758-601ef40a-9b89-460e-99cc-05a086dbc269.png)

We now want to persist data on mongodb and limit the access. This is how we persist data to a named volume:
```bash
docker run --name mongodb --rm -d -v data:/data/db --network goals-net mongo
```
The data now perists if I stop the docker container.

We can now add username and password:
```bash
docker run --name mongodb --rm -d -v data:/data/db --network goals-net -e MONGO_INITDB_ROOT_USERNAME=tom -e MONGO_INITDB_ROOT_PASSWORD=secret  mongo
```
We now need to add the username and password to our mongodb connection string:

```javascript

mongoose.connect(
  'mongodb://tom:secret@mongodb:27017/course-goals?authSource=admin',
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error('FAILED TO CONNECT TO MONGODB');
      console.error(err);
    } else {
      console.log('CONNECTED TO MONGODB');
      app.listen(3001);
    }
  }
);
```

We now add a named volume for the logs for the backend and add a mount for our code base and the app folder on the container and an anonymous volume for our node modules:
```bash
 docker run --name goals-backend -v logs:/app/logs -v /home/tom/Projects/Docker-And-Kubernetes/multi-01-starting-setup/backend:/app -v /app/node_modules --rm -p 3001:3001 --network goals-net goals-node
 ```
We have also added nodemon and changed the command in the Dockerfile backend to npm start.


### Docker Compose: Elegant Multi-Container Orchestration

Docker compose replaces docker build and docker run commands with one configuration file and a set of
orchestration commands to start all images at once.

![image](https://user-images.githubusercontent.com/27693622/232341221-e46c2024-e507-48aa-bfd2-d7a6aaa77b29.png)

The versions of docker-compose are listed here:
https://docs.docker.com/compose/compose-file/compose-file-v3/

We can now start the docker images with:
```yaml
version: "3.8"
services:
  mongodb:
    image: 'mongo'
    volumes:
      - data:/data/db
    env_file:
      - ./env/mongo.env
#  backend:
#    image:
#
#  frontend:
volumes:
  data:
```

and run the file with:
```bash
docker-compose up
```

We can delete the images, containers and volumes with:
```bash
docker-compose down -v
```

This is the docker-compose file with all the services:
```yml

version: "3.8"
services:
  mongodb:
    image: 'mongo'
    volumes:
      - data:/data/db
    env_file:
      - ./env/mongo.env
  backend:
    build: ./backend
    ports:
      - '3001:3001'
    volumes:
      - logs:/app/logs
      - ./backend:/app
      - /app/node_modules
    env_file:
      - ./env/backend.env
    depends_on:
      - mongodb
  frontend:
    build: ./frontend
    ports:
      - '3000:3000'
    volumes:
      - ./frontend/src:/app/src
    stdin_open: true
    tty: true
    depends_on:
      - backend

volumes:
  data:
  logs:
```

### Working with "Utility Containers" and executing commands in Containers
![image](https://user-images.githubusercontent.com/27693622/232348989-19ada890-b2a8-47a4-9aeb-8fb2feb58b70.png)

We build the dockerfile:
```dockerfile
FROM node:14-alpine

WORKDIR /app
```
with:
```bash
docker build -t node-util .
```

We can use the utility containers for creating our environment:
```bash
docker run -it -v /home/tom/Projects/Docker-And-Kubernetes/utility-containers:/app node-util npm init
```

we can use the utility container to install express:
```bash
docker run -it -v /home/tom/Projects/Docker-And-Kubernetes/utility-containers:/app my-npm install express --save
```

This is quite long so we can use docker-compose:
```yaml
version: "3.8"
services:
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```

We run the file with:
```bash
docker-compose run npm init
```

### More complex Dockerized Project
We will now practice a more complex container setup with Laravel and PHP.

![image](https://user-images.githubusercontent.com/27693622/232719934-3e2442b8-da24-47ca-a4e4-0398f95496ca.png)

We first add nginx:
```yaml
version: "3.8"

services:
  server:
    image: 'nginx:stable-alpine'
    ports:
      - '8000:80'
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```
and the configuration for the nginx.conf file:
```nginx configuration
server {
    listen 80;
    index index.php index.html;
    server_name localhost;
    root /var/www/html/public;
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:3000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

We then add our php Dockerfile:
```dockerfile
FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

RUN docker-php-ext-install pdo pdo_mysql
```
The base php image invokes the interpreter for our layered php image. We can now add composer to our docker-compose file:
```yaml
version: "3.8"

services:
  server:
    image: 'nginx:stable-alpine'
    ports:
      - '8000:80'
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  php:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
  mysql:
    image: 'mysql:5.7'
    env_file:
      - ./env/mysql.env
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html
```

We then set up the laravel project:
```bash
docker-compose run --rm composer create-project --prefer-dist laravel/laravel .
```

and run the relevant services with:

```bash
docker-compose up server php mysql
```

We now have a running laravel page:
![image](https://user-images.githubusercontent.com/27693622/232803104-f62ca2d5-508c-479d-ab64-45c62bc00066.png)

We can also make server depend on mysql and php and then ensure that the docker-compose uses the latest images with --build:
```bash
docker-compose up -d --build server
```

### Deploying Docker Containers
We will now deploy our docker containers to a remote server. We will learn about the deployment overview and general process.
We will also look at concrete deployment scenarios, examples and problems. We will look at the manual and managed approaches.
We will AWS as our cloud provider. 

#### Containers
- standardized unit for shipping
- they are independent of other containers
- we want the same environment for development, testing and production so that the application works the same way in all environments
- We benefit from the isolated standalone environment in development and production
- we have reproducible environments that are easy to share and use
- there are no surpises - what works on a local machine also works in production

#### Difference between production and development
- bind mounts shouldn't be used in production
- containerized apps might need a build step (e.g. React apps)
- multi-container projects might need to be split across multiple hosts / remote machines
- trade-offs between control and responsibility might be worth it

#### Deployment Process and Providers
We will start with a NodeJS environment with no database and nothing else. A possible deployment process is:
- Install docker on a remote host (e.g. via SSH), push and pull image and run container based on image on remote host

#### Deploy to AWS EC2
AWS EC2 is a service that allows us to spin up and manage our own remote machines.
1. Create and launch an EC2 instance, VPC and security group
2. Configure security group to expose all required ports to www
3. Connect to instance (SSH), install Docker and run container

### Commands to open port 80 and port 443:
I saw these commands for opening port 80 and port 443 on ubuntu:
```bash
tom@tom-ubuntu:~$ sudo ufw allow http
[sudo] password for tom:
Rules updated
Rules updated (v6)
tom@tom-ubuntu:~$ sudo ufw allow https
Rules updated
Rules updated (v6)
```
I then build the docker image and run the container:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker build -t node-dep-example .
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker run -d --rm --name node-dep -p 80:80 node-dep-example
f7c9d35545fb0a0c28f5077b271b8669b9a8c2a829a0e6d230e021610a9a0a03
```

![image](https://user-images.githubusercontent.com/27693622/233949979-6687249c-f4ec-4215-9f6d-603c4dbb8f25.png)

### Bind mounts, volumes & COPY
In development the container should encapsulate the runtime environment but not necessarily the code.
We can use "Bind Mounts" to provide our local host project files to the running container. This allows for instant
updates without restarting the container.
In production the container should really work standalone, and we should not have source code on our remote machine.
This image / container is the "single source of truth". There should be nothing around the container on the hosting machine.
When we build for production we use COPY instead of bind mounts to copy a code snapshot into the image. This ensures that every
image runs without any extra, surrounding configuration or code.

### Install docker on ec2
We have started an ec2 instance and connected to the instance. This tutorial is quite useful for connecting to ec2:
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html

These are the commands for installing docker on ubuntu:
```bash
sudo yum update -y
sudo yum -y install docker
 
sudo service docker start
 
sudo usermod -a -G docker ec2-user
```
We then log out and back in after running the commands. Once we are logged back in we can run the following commands:
```bash
sudo systemctl enable docker
```
For me on my ec2 instance docker version shows:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker version
Client:
 Version:           20.10.17
 API version:       1.41
 Go version:        go1.19.3
 Git commit:        100c701
 Built:             Mon Mar 13 22:41:42 2023
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server:
 Engine:
  Version:          20.10.17
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.19.3
  Git commit:       a89b842
  Built:            Mon Mar 13 00:00:00 2023
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.19
  GitCommit:        1e1ea6e986c6c86565bc33d52e34b81b3e2bc71f
 runc:
  Version:          1.1.4
  GitCommit:        5fd4c4d144137e991c4acebb2146ab1483a97925
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

This stack overflow post was useful for installing docker on ec2:
https://stackoverflow.com/questions/53918841/how-to-install-docker-on-amazon-linux2/61708497#61708497

This is what shows for docker ps, docker images and docker ps -a:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[ec2-user@ip-172-31-14-37 ~]$ docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
[ec2-user@ip-172-31-14-37 ~]$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

This link has general instructions for installing docker engine:
https://docs.docker.com/engine/install/

### Pushing our local image to the code:
There are two options here:
1. Deploy source
- build image on remote machine
- push source code to remote machine, run docker build and docker run
- this is a bit overly complex
2. Deploy built image
- build image before deployment (e.g. on local machine)
- Just execute docker run

We are going to deploy our image to dockerhub for now. First we will log into dockerhub locally:
```bash
tom@tom-ubuntu:~$ docker login
Authenticating with existing credentials...
WARNING! Your password will be stored unencrypted in /home/tom/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
We then create a repository on docker hub:
![image](https://user-images.githubusercontent.com/27693622/233958315-a1e20135-1e27-42f9-b09a-464b03bc0b12.png)

We then add a .dockerignore file to our project:
```bash
node_modules
Dockerfile
```
This avoids adding unecessary files. Next we build the image:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker build -t node-dep-example-1 .
```
We then tag our image for pushing to docker hub:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker tag node-dep-example-1 tomspencerlondon/node-example-1
```

We then push the image to docker hub:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker push tomspencerlondon/node-example-1
Using default tag: latest
The push refers to repository [docker.io/tomspencerlondon/node-example-1]
9d59a013007b: Pushed 
2972d38db3fa: Pushed 
8fecd54a1233: Pushed 
4f52e9ae1242: Pushed 
31f710dc178f: Mounted from library/node 
a599bf3e59b8: Mounted from library/node 
e67e8085abae: Mounted from library/node 
f1417ff83b31: Mounted from library/php 
latest: digest: sha256:a1924592ca810836bbf78f9e2bd2a0f83848d1f8ecbfe18f8b0224f0319ac491 size: 1990
```
Now we can run the image on our remote machine:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker run -d --rm -p 80:80 tomspencerlondon/node-example-1
Unable to find image 'tomspencerlondon/node-example-1:latest' locally
latest: Pulling from tomspencerlondon/node-example-1
f56be85fc22e: Pull complete 
8f665685b215: Pull complete 
e5fca6c395a6: Pull complete 
561cb69653d5: Pull complete 
aa19ccf4c885: Pull complete 
06bc5b182177: Pull complete 
86c3c7ad1831: Pull complete 
4b21eb2ee505: Pull complete 
Digest: sha256:a1924592ca810836bbf78f9e2bd2a0f83848d1f8ecbfe18f8b0224f0319ac491
Status: Downloaded newer image for tomspencerlondon/node-example-1:latest
fbe136f3958a0a9b6f258064625d8968b73ca52da9cce4e3278141912e024463
```

We can then check the container is running:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED          STATUS          PORTS                               NAMES
fbe136f3958a   tomspencerlondon/node-example-1   "docker-entrypoint.s…"   34 seconds ago   Up 32 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   happy_lamport
```

We can also access the site:
![image](https://user-images.githubusercontent.com/27693622/233960782-2df87a02-d64b-4200-8b66-eee57dbb37c3.png)

If we want to make changes to our application we can make the change and rebuild the image:
```bash
 docker build -t node-dep-example-1 .
```

We then tag the image:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker tag node-dep-example-1 tomspencerlondon/node-example-1
```
and then push the image to docker hub:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker push tomspencerlondon/node-example-1
Using default tag: latest
The push refers to repository [docker.io/tomspencerlondon/node-example-1]
b655b01209f7: Pushed 
2972d38db3fa: Layer already exists 
8fecd54a1233: Layer already exists 
4f52e9ae1242: Layer already exists 
31f710dc178f: Layer already exists 
a599bf3e59b8: Layer already exists 
e67e8085abae: Layer already exists 
f1417ff83b31: Layer already exists 
latest: digest: sha256:eb1a6659d93be31f9103739709dbe27806ed70d75b8159586074ee5dcf2f9644 size: 1990
```
We then stop the running container on the ec2 instance:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED          STATUS          PORTS                               NAMES
fbe136f3958a   tomspencerlondon/node-example-1   "docker-entrypoint.s…"   34 seconds ago   Up 32 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   happy_lamport
[ec2-user@ip-172-31-14-37 ~]$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED          STATUS          PORTS                               NAMES
fbe136f3958a   tomspencerlondon/node-example-1   "docker-entrypoint.s…"   22 minutes ago   Up 22 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   happy_lamport
[ec2-user@ip-172-31-14-37 ~]$ docker stop fbe
fbe
```
We then pull our image from docker hub:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker pull tomspencerlondon/node-example-1
Using default tag: latest
latest: Pulling from tomspencerlondon/node-example-1
f56be85fc22e: Already exists 
8f665685b215: Already exists 
e5fca6c395a6: Already exists 
561cb69653d5: Already exists 
aa19ccf4c885: Already exists 
06bc5b182177: Already exists 
86c3c7ad1831: Already exists 
94e37dedf8d5: Pull complete 
Digest: sha256:eb1a6659d93be31f9103739709dbe27806ed70d75b8159586074ee5dcf2f9644
Status: Downloaded newer image for tomspencerlondon/node-example-1:latest
docker.io/tomspencerlondon/node-example-1:latest
```
We then run the image:
```bash
[ec2-user@ip-172-31-14-37 ~]$ docker run -d --rm -p 80:80 tomspencerlondon/node-example-1
4ab3476b1d8a7e3dbe2d55558dca4cbc3f4500de32049757c31831e1100c9c76
```
We can then see the change we made:
![image](https://user-images.githubusercontent.com/27693622/233966400-036eb58f-6058-4081-8240-30e23f75a7f1.png)





