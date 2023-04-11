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