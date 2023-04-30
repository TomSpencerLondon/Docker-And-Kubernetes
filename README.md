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
date or state by default. A container is an isolated unit of software based on an image. A container is a running
instance
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

The temp folder stores files before copying to feedback. The temp file will be temporary storage. We will persist data
in the
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
reflected on the other folder. Volumes are persisted if a container shuts down. The volume will not be removed when a
container is
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

The named volume will not be deleted by Docker when the container is shut down. Named volumes are not attached to
containers. The
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

Anonymous volumes are created specifically for a container. They do not survive --rm and cannot be used to share across
containers.
Anonymous volumes are useful for locking in data which is already in a container and which you don't want to be
overwritten.
They still create a counterpart on the host machine.

Named volumes are created by -v with name:/PATH. They are not tied to specific containers and survive shutdown and
restart of the container.
These can be used to share across containers and shutdowns and removals.

Bind mounts are given a place to save data on the host machine. They also survive shutdown / restart of the docker
container.

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
        res.status(200).json({movies: response.data});
    } catch (error) {
        res.status(500).json({message: 'Something went wrong.'});
    }
});


app.get('/people', async (req, res) => {
    try {
        const response = await axios.get('https://swapi.dev/api/people');
        res.status(200).json({people: response.data});
    } catch (error) {
        res.status(500).json({message: 'Something went wrong.'});
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
    {useNewUrlParser: true},
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

The connection to the outside WWW works. Sending requests to the web works. The connection to the server on our
localhost
is not working.
Instead of localhost we need to use host.docker.internal to communicate with the host:

```javascript
mongoose.connect(
    'mongodb://host.docker.internal:27017/swfavorites',
    {useNewUrlParser: true},
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
    {useNewUrlParser: true},
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

The above is a common setup for a web application which includes a backend database with a front end application which
brings
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

We now add a named volume for the logs for the backend and add a mount for our code base and the app folder on the
container and an anonymous volume for our node modules:

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

The base php image invokes the interpreter for our layered php image. We can now add composer to our docker-compose
file:

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

We can also make server depend on mysql and php and then ensure that the docker-compose uses the latest images with
--build:

```bash
docker-compose up -d --build server
```

### Deploying Docker Containers

We will now deploy our docker containers to a remote server. We will learn about the deployment overview and general
process.
We will also look at concrete deployment scenarios, examples and problems. We will look at the manual and managed
approaches.
We will AWS as our cloud provider.

#### Containers

- standardized unit for shipping
- they are independent of other containers
- we want the same environment for development, testing and production so that the application works the same way in all
  environments
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
This image / container is the "single source of truth". There should be nothing around the container on the hosting
machine.
When we build for production we use COPY instead of bind mounts to copy a code snapshot into the image. This ensures
that every
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

#### Docker is awesome!

- only docker needs to be installed (no other runtimes or tools)
- uploading our code is easy
- the image is the exact same app and environment as on our machine

#### "Do it your self" approach - Disadvantages

- we fully own the remote machine - we are responsible for it (and its security)
- we ensure all the system software stays updated
- we have to manage the network and security groups / firewall
- it is easy to set up an insecure instance
- SSHing into the machine to manage it can be annoying

We might want to be able to run commands on a local machine to deploy the image.

#### From manual deployment to managed services

We may want less control so that we have less responsibility.
Instead of running our own EC2 instance we might want a managed service. For the ec2 instance we need to
create the instance, manage it, keep it updated, monitor it and scale the instances. If we have the admin/cloud expert
knowledge this is great.

We might go for a managed remote machine. Here AWS ECS can help us. ECS stands for Elastic Container Service.
It will help us with management, monitoring and scaling. The advantage is that the creation, management, updating,
monitoring
and scaling is simplified. This is great if we simply want to deploy our app / containers. We therefore have less
control but
also less responsibility. We now use a service provided by a cloud provider and we have to follow the rules of the
service.
Running containers is no longer our responsibility but we use the tools of the cloud provider for the service we want to
use.

NB: We really should double-check to remove ALL created resources (e.g. load balancers, NAT gateways etc.) once we're
done - otherwise, monthly costs can be much higher!
The AWS pricing page is quite useful for costs:
https://aws.amazon.com/pricing/

### Deploying with AWS ECS

![image](https://user-images.githubusercontent.com/27693622/233976615-9a8cf529-cc49-4d7e-96cf-d597827dff44.png)

First I will push my image to Elastic Container Registry (ECR). I will need to login to ECR:

```bash
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 706054169063.dkr.ecr.eu-west-2.amazonaws.com
```

I will then build the image and tag it for pushing to ECR:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker build -t node-example .
[+] Building 0.9s (11/11) FINISHED                                                                       
 => [internal] load .dockerignore                                                                   0.0s
 => => transferring context: 63B                                                                    0.0s
 => [internal] load build definition from Dockerfile                                                0.0s
 => => transferring dockerfile: 153B                                                                0.0s
 => [internal] load metadata for docker.io/library/node:14-alpine                                   0.8s
 => [auth] library/node:pull token for registry-1.docker.io                                         0.0s
 => [1/5] FROM docker.io/library/node:14-alpine@sha256:434215b487a329c9e867202ff89e704d3a75e554822  0.0s
 => [internal] load build context                                                                   0.0s
 => => transferring context: 581B                                                                   0.0s
 => CACHED [2/5] WORKDIR /app                                                                       0.0s
 => CACHED [3/5] COPY package.json .                                                                0.0s
 => CACHED [4/5] RUN npm install                                                                    0.0s
 => CACHED [5/5] COPY . .                                                                           0.0s
 => exporting to image                                                                              0.0s
 => => exporting layers                                                                             0.0s
 => => writing image sha256:442e42a74350cde5834ac7eef70efdcb3218c0099d6f082f15011b173950ae87        0.0s
 => => naming to docker.io/library/node-example                                                     0.0s
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker tag node-example:latest 706054169063.dkr.ecr.eu-west-2.amazonaws.com/node-example:latest
```

I will then push the image to ECR:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/deployment-01-starting-setup$ docker push 706054169063.dkr.ecr.eu-west-2.amazonaws.com/node-example:latest
The push refers to repository [706054169063.dkr.ecr.eu-west-2.amazonaws.com/node-example]
b655b01209f7: Pushed 
2972d38db3fa: Pushed 
8fecd54a1233: Pushed 
4f52e9ae1242: Pushed 
31f710dc178f: Pushed 
a599bf3e59b8: Pushed 
e67e8085abae: Pushed 
f1417ff83b31: Pushed 
latest: digest: sha256:eb1a6659d93be31f9103739709dbe27806ed70d75b8159586074ee5dcf2f9644 size: 1990
```

This video is good for setting up AWS ECR, ECS and Fargate:
https://www.youtube.com/watch?v=RgLt3R2A20s

We have done the set up for ECR so we are now on ECS and Fargate

#### Cluster

First we create a cluster. We set a cluster name and use the default vpc. We use all three subnets.
We use AWS Fargate serverless and then create the cluster. Cloud Formation keeps a record of the deployment.

#### Task Definition

We then define our task. The task definition can be nodejs-demo. We then add the uri for the ECR repository and give it
a name.
We choose the container port with http protocol. We will only use one container. We then use the AWS Fargate serverless
environment.
We choose 2GB of memory and the task execution role is already set. We then create the task definition.

#### Service

Next we create a service on the cluster. For the service we use launch type Fargate and use the Service for deployment
configuration
and the Task we defined earlier for our family. We then need to create a security group. We need to open port 80 for
http so we create
a new security group. We then add the http protocol rule for the security group. We also select public IP.
We then create the service. We also need to give the service a new. The service deployment will take a few minutes.
We then go to tasks and look at our task and access the public IP:

![image](https://user-images.githubusercontent.com/27693622/234000188-f93eed06-7bfd-483b-ab80-7b363e73a238.png)

Next we will create an application load balancer. We will delete the service and then create one with an application
load
balancer. We then create a new service and choose the load balancer type. We then create a new load balancer. We will
use application load balancer.
We assign the loadbalancer a name. We create a new listener for port 80 and a new target group. We can use service
autoscaling
with 1 and 4 for our minimum and maximum tasks. The target value will be 70%. We must remember to add a security group
for the load balancer
and the service. We then create the service. We can then access the load balancer public IP:

![image](https://user-images.githubusercontent.com/27693622/234018436-9113e528-bf31-4e67-9a19-6f6d57828af9.png)

### ECS - elastic container service

This link is useful for aplication loadbalancing ecs tasks:
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html

### Getting started with Kubernetes

In this section we will learn about deploying docker containers with Kubernetes. This allows independent container
orchestration.
We will understand container deployment challenges. We will also define Kubernetes and learn why it is useful.
We will also learn about Kubernetes concepts and components. This link is useful for getting started with Kubernetes:
https://kubernetes.io/

As mentioned on the above link:
Kubernetes is an open-source system for automating deployment, scaling and management of containerized applications.

When we think about deploying containers, we might have a problem. Manually deploying servers and containers is not
scalable.
Manual deployment of containers is hard to maintain, error-prone and annoying. even beyond security and configuration
concerns.
Containers might crash / go down and need to be replaced. We would want to replace containers but when manually
deploying containers
we would have to manually monitor and deploy containers. We can't sit the entire day watching containers to see if they
are running or not.
We might need more container instances for traffic spikes, and we might need to scale down when traffic is low. We also
might want traffic to
be equally distributed across multiple instances of the same container. We might also want to deploy containers across
multiple servers.
So far when we have worked locally we have only deployed one container instance for each service. AWS ECS does help us
with
container health checks and automatic re-deployment, autoscaling and load balancing. AWS ECS does lock us into the
service.
If we use a specific service we are locked into that service. We might want to use a different service in the future.
AWS ECS thinks in terms of clusters tasks and clusters. We can write configuration files and use the AWS CLI to deploy
containers.
We will, however, always be locked into the AWS ECS service. The cloud files would only work with ECS.

### Kubernetes to the Rescue

With Kubernetes we have a way of defining our deployments independent from the cloud service we are using. Kubernetes is
an open source system and
standard for orchectrating container deployments. It can help with automatic deployment, scaling and management of
containerized applications.
Kubernetes allows us to write down a configuration file where we define the desired state of our application and we can
pass this configuration
to any cloud provider or tool to deploy our application. This is an example of the kind of configuration Kubernetes
offers:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  annotations:

spec:
  selector:
    app: auth-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

This configuration would work with any cloud provider. We can then use the configuration to describe the to-be-created
and to-be-managed resources
of the Kubernetes Cluster. We can merge cloud-provider specific settings into the main file. If we want to use a
different cloud provider we can then
replace the cloud provider specific settings:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal-access-log-enabled: "true"
spec:
  selector:
    app: auth-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

Kubernetes is powerful and interesting, but we do need to understand what it is not. It is not a cloud service provider.
It is an open-source project
and collection of configuration options. It is not a service by a cloud service provider, it can be used with any cloud
provider.
Kubernetes is not a software but a collection of concepts and tools that can help us with deployment on any provider of
our choice. It is not a paid
service but a free open-source project. It is not a tool for deploying containers but a tool for orchestrating container
deployments.
Kubernetes is like docker-compose for multiple machines. Docker-compose is for container orchestration one machine and
Kubernetes is for multiple machines.

### Kubernetes deployment architecture

![image](https://user-images.githubusercontent.com/27693622/235035081-9b5a85ff-d788-4c73-8a94-86ec3aca219f.png)

There is an important clarification on things we have to do and what Kubernetes does for us. We have to create a
Kubernetes cluster and the Node instances (Worker + Master Nodes).
We have to set up the API server, kubelet and other Kubernetes services / software on Nodes. We might need to create
other cloud provider resources that might be needed
(e.g. Load Balancer, Filesystems). Kubernetes will not set up the resources. Kubernetes will manage the pods and create
them for us. It will monitor the pods and utilize
the provided resources to apply your configuration / goals. Kubernetes does not create the cluster, it will manage it
for us.

### Worker nodes

What happens on the worker nodes (e.g. creating a Pod) is managed by the Master Nodes.

![image](https://user-images.githubusercontent.com/27693622/235261777-caba119e-7544-4885-bb98-e9fdcd9b8bad.png)

With Kubernetes we define the desired state of our application. Kubernetes will then create the resources for us.
Kubernetes will then monitor the resources and
make sure the desired state is maintained. If a pod crashes, Kubernetes will create a new pod. If we want to scale up,
Kubernetes will create new pods.
If we want to scale down, Kubernetes will delete pods. If we want to update our application, Kubernetes will create new
pods with the new version and delete the old pods.

### Master Node

The master node is the brain of the cluster. It is responsible for managing the cluster. It is responsible for
monitoring the cluster and making sure the desired state is maintained.

![image](https://user-images.githubusercontent.com/27693622/235262512-11b9ffbf-e73d-459e-b6f1-d0808e7215aa.png)

### Core components

| Component   | Description                                                                                                                     |
|-------------|---------------------------------------------------------------------------------------------------------------------------------|
| Cluster     | A set of Node machines which are running the Containerized Application (Worker Nodes) or control other Nodes (Master Node)      |
| Node        | Physical or virtual machine with a certain hardware capacity which hosts one or multiple Pods and communicates with the Cluster |
| Master Node | Custer control plane, managing the Pods across Worker Nodes                                                                     |
| Worker Node | Hosts Pods, running App Containers (+ resources)                                                                                |
| Pods        | Pods hold the actual running App Containers and their required resources (e.g. volumes)                                         |
| Containers  | Normal (Docker) Containers                                                                                                      |
| Services    | Logical set (group) of Pods with a unique, Pod- and Container- independent IP address                                           |

So, Kubernetes is a collection of concepts and tools. Specifically, a Kubernetes is required to run Containers. A
Kubernetes
Cluster is a network of machines.

These machines are called "Nodes" in the Kubernetes world and there are two kinds of Nodes:

- The Master Node: Hosts the "Control Plane" - i.e. it is the control center which manages your deployed resources.
- Worker Nodes: Machines where the actual Containers are running on

The Master Node hosts a couple of tools / processes:

- An API Server: Responsible for communicating with the Worker Nodes (e.g. to launch a new Container)
- A Scheduler: Responsible for managing the Containers, e.g. determine on which Node to launch a new Container

The docs are useful for understanding the components:
https://kubernetes.io/docs/concepts/overview/components/

On Worker Nodes, we got the following running "tools" / processes:

- kubelet service: The counterpart for the Master Node API Server, communicates with the Control Plane
- Container runtime (e.g. Docker): used for running and controlling the Containers
- kube-proxy service: responsible for Container network (and Cluster) communication and access

If you create your own Kubernetes Cluster from scratch, you need to create all these machines and then install
the Kubernetes software on those machines - of course you also need to manage permissions etc.

Kubernetes creates, runs, stops and manages Containers for you. It does this in Pods which are smallest unit in
Kubernetes.
With Kubernetes, you don't manage Containers but rather Pods which then manage the Containers.

### Kubernetes in Action - Diving into the Core Concepts

We are now going to dive into Kubernetes and start working with it. We will look at:

- Kubernetes & Testing Environment Setup
- Working with Kubernetes Objects

| What Kubernetes will do                                                                | What we need to do                                                                             |
|----------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Kubernetes helps with managing the Pods                                                | Kubernetes will not create the infrastructure                                                  |
| Create objects (e.g. Pods) and manage them                                             | Create the Cluster and the Node Instances (Worker + Master Nodes)                              |
| Monitor Pods and re-create them, scale Pods etc.                                       | Setup API Server, kubelet and other Kubernetes services / software on Nodes                    |
| Kubernetes utilizes the provided (cloud) resources to apply your configuration / goals | Create other (cloud) provider resources that might be needed (e.g. Load Balancer, Filesystems) |

Tools like kubermatic can be useful for creating remote machines:
https://www.kubermatic.com/

AWS has a dedicated Elastic Kubernetes Service (EKS) which can be used to create a Kubernetes Cluster:
https://aws.amazon.com/eks/

### Installation

To run Kubernetes locally, we will need a Cluster with a Master Node and Worker Nodes. We also need to install all
required
"software" (services). We will also need Kubectl, a CLI tool, to interact with the Cluster. We use kubectl to set the
configuration
mantained by Kubernetes. The Master Node applies the commands and ensures they are executed. The Kubectl tool is used to
communicate with the Master Node. To use a marshall metaphore Kubectl is the commander in chief, the Master Node is the
general
and the Worker Nodes are the soldiers.

We will use Minikube to run Kubernetes locally. Minikube is a tool that runs a single-node Kubernetes cluster in a
virtual machine.
This is quite good for Kubectl:
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

This link is quite good for minikube:
https://minikube.sigs.k8s.io/docs/start/

### Understanding Kubernetes Objects

Kubernetes works with objects: Pods, Deployments, Services, Volumes etc.
We can create the objects by executing a kubectl command. Objects can be created imperatively or declaratively.
Imperatively means we tell Kubernetes what to do. Declaratively means we tell Kubernetes what we want and Kubernetes
will figure out how to do it.

#### The Pod object

- The smallest unit in Kubernetes
- Contains and runs one or multiple containers (most common use case is "one container per Pod")
- Pods contain shared resources (e.g. volumes for all Pod containers)
- Pods have cluster internal IP addresses by default
- Containers inside a Pod can communicate via localhost
- Pods are designed to be ephemeral - Kubernetes will start, stop and replace them as needed
- Pods are not designed to be persistent - if a Pod crashes, it will be replaced by a new one and the data is lost
- Pods are wrappers around Containers
- For Pods to be managed for us, we need a "Controller" i.e. a "Deployment"

#### The Deployment Object

- Controls multiple Pods
- set a desired state, Kubernetes then changes the actual state to match the desired state
- Define which Pods and containers to run and the number of instances
- Deployments can be paused, deleted and rolled back
- Deployments can be scaled dynamically and automatically
- You can change the number of desired Pods as needed
- Deployments manage a Pod for you, you can also create multiple Deployments

We don't directly control Pods, instead we use Deployments to set up the desired end state.

### Example Project

We will create a simple Node.js application and deploy it to Kubernetes. We will use a Docker image to run the
application.
The app has two endpoints: root and /error:

```javascript
const express = require('express');

const app = express();

app.get('/', (req, res) => {
    res.send(`
    <h1>Hello from this NodeJS app!</h1>
    <p>Try sending a request to /error and see what happens</p>
  `);
});

app.get('/error', (req, res) => {
    process.exit(1);
});

app.listen(8080);
```

We will deploy this application to our Kubernetes cluster. We still need to use Docker to create the image.
Kubernetes needs an image to run the container.

We build the image:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ docker build -t kub-first-app .
[+] Building 15.6s (11/11) FINISHED                                                                      
 => [internal] load .dockerignore                                                                   0.1s
 => => transferring context: 63B                                                                    0.0s
 => [internal] load build definition from Dockerfile                                                0.1s
 => => transferring dockerfile: 157B                                                                0.0s
 => [internal] load metadata for docker.io/library/node:14-alpine                                   1.7s
 => [auth] library/node:pull token for registry-1.docker.io                                         0.0s
 => [internal] load build context                                                                   0.1s
 => => transferring context: 1.31kB                                                                 0.0s
 => [1/5] FROM docker.io/library/node:14-alpine@sha256:434215b487a329c9e867202ff89e704d3a75e554822  8.8s
 => => resolve docker.io/library/node:14-alpine@sha256:434215b487a329c9e867202ff89e704d3a75e554822  0.0s
 => => sha256:434215b487a329c9e867202ff89e704d3a75e554822e07f3e0c0f9e606121b33 1.43kB / 1.43kB      0.0s
 => => sha256:4e84c956cd276af9ed14a8b2939a734364c2b0042485e90e1b97175e73dfd548 1.16kB / 1.16kB      0.0s
 => => sha256:0dac3dc27b1ad570e6c3a7f7cd29e88e7130ff0cad31b2ec5a0f222fbe971bdb 6.44kB / 6.44kB      0.0s
 => => sha256:f56be85fc22e46face30e2c3de3f7fe7c15f8fd7c4e5add29d7f64b87abdaa09 3.37MB / 3.37MB      1.2s
 => => sha256:8f665685b215c7daf9164545f1bbdd74d800af77d0d267db31fe0345c0c8fb8b 37.17MB / 37.17MB    7.0s
 => => sha256:e5fca6c395a62ec277102af9e5283f6edb43b3e4f20f798e3ce7e425be226ba6 2.37MB / 2.37MB      1.1s
 => => extracting sha256:f56be85fc22e46face30e2c3de3f7fe7c15f8fd7c4e5add29d7f64b87abdaa09           0.3s
 => => sha256:561cb69653d56a9725be56e02128e4e96fb434a8b4b4decf2bdeb479a225feaf 448B / 448B          1.3s
 => => extracting sha256:8f665685b215c7daf9164545f1bbdd74d800af77d0d267db31fe0345c0c8fb8b           1.1s
 => => extracting sha256:e5fca6c395a62ec277102af9e5283f6edb43b3e4f20f798e3ce7e425be226ba6           0.1s
 => => extracting sha256:561cb69653d56a9725be56e02128e4e96fb434a8b4b4decf2bdeb479a225feaf           0.0s
 => [2/5] WORKDIR /app                                                                              0.5s
 => [3/5] COPY package.json .                                                                       0.1s
 => [4/5] RUN npm install                                                                           4.0s
 => [5/5] COPY . .                                                                                  0.1s
 => exporting to image                                                                              0.2s 
 => => exporting layers                                                                             0.2s 
 => => writing image sha256:df647099c29ed38622ae40476575c72e1a9198c5d0efeba401a7c0d5188eec11        0.0s 
 => => naming to docker.io/library/kub-first-app                                                    0.0s
```

We start minikube:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ minikube start
😄  minikube v1.29.0 on Ubuntu 22.10
🎉  minikube 1.30.1 is available! Download it: https://github.com/kubernetes/minikube/releases/tag/v1.30.1
💡  To disable this notice, run: 'minikube config set WantUpdateNotification false'

✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🤷  docker "minikube" container is missing, will recreate.
🔥  Creating docker container (CPUs=2, Memory=3900MB) ...
🐳  Preparing Kubernetes v1.26.1 on Docker 20.10.23 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

```

We then check the status of minikube:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

The above result shows us that our minikube instance is running. We can now send the instruction to create a deployment
to the cluster. We can check the available commands with:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl help
kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/

Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new
Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and
label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller

Cluster Management Commands:
  certificate     Modify certificate resources.
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events

Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Experimental: Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL.

Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or
powershell)

Other Commands:
  alpha           Commands for features in alpha
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
```

This is the list of kubectl create commands:

```bash
Available Commands:
  clusterrole           Create a cluster role
  clusterrolebinding    Create a cluster role binding for a particular cluster role
  configmap             Create a config map from a local file, directory or literal value
  cronjob               Create a cron job with the specified name
  deployment            Create a deployment with the specified name
  ingress               Create an ingress with the specified name
  job                   Create a job with the specified name
  namespace             Create a namespace with the specified name
  poddisruptionbudget   Create a pod disruption budget with the specified name
  priorityclass         Create a priority class with the specified name
  quota                 Create a quota with the specified name
  role                  Create a role with single rule
  rolebinding           Create a role binding for a particular role or cluster role
  secret                Create a secret using specified subcommand
  service               Create a service using a specified subcommand
  serviceaccount        Create a service account with the specified name
  token                 Request a service account token
```

We then need to deploy our image to dockerhub:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ docker tag kub-first-app tomspencerlondon/kub-first-app
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ docker push tomspencerlondon/kub-first-app
```

We can then create a deployment using the image we have pushed to docker hub:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl create deployment first-app --image=tomspencerlondon/kub-first-app
deployment.apps/first-app created
```

We can then check the status of the deployment:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   1/1     1            1           29s
```

We can then check the status of the pods:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
first-app-886784874-ssbv9   1/1     Running   0          48s
```

We can then check the status of the cluster:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ minikube dashboard
🔌  Enabling dashboard ...
    ▪ Using image docker.io/kubernetesui/dashboard:v2.7.0
    ▪ Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
💡  Some dashboard features require the metrics-server addon. To enable all features please run:

	minikube addons enable metrics-server	


🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
🎉  Opening http://127.0.0.1:35463/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...
Opening in existing browser session.
```

This shows the cluster in our dashboard:
![image](https://user-images.githubusercontent.com/27693622/235322108-a3a70f1b-6e30-463c-b06e-6a734e99f92b.png)

We can see the status of the cluster. At the moment the cluster has a private IP address.

### Kubectl behind the scenes

Here, we have created a deployment object which is responsible for keeping a set of pods running. We can see this by
running the following command:

```bash
kubectl create deployment --image ..
```

This creates a Master Node (Control Plane). The scheduler analyzes currently running Pods and finds the best Node for
the new Pods.
Kubelet manages the Pods and containers. The Pod inside the worker node runs our specified image inside a container.

### The Service Object

To reach a Pod we need a Service object. The Service object exposes Pods to the Cluster or externally. Pods already have
an internal
IP address. The IP address changes when a Pod is replaced so we can't rely on the Pod keeping the IP address. Finding
Pods is hard if the IP
changes all the time. Services group Pods with a shared IP which won't change. We can move multiple pods inside a
service
to expose the address inside the cluster and also to allow external access to Pods. The default for the Service IP is
internal but this can be changed.
Without Services, Pods are very hard to reach and communication is difficult. Reaching a Pod from outside the Cluster is
not possible at all without Services.

### Exposing a deployment with a Service

We can expose a deployment with a service using the following command:

```bash

tom@tom-ubuntu:~$ kubectl expose deployment first-app --type=LoadBalancer --port=8080
service/first-app exposed
```

We can then list the services:

```bash
tom@tom-ubuntu:~$ kubectl get services
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
first-app    LoadBalancer   10.106.173.108   <pending>     8080:32470/TCP   15s
kubernetes   ClusterIP      10.96.0.1        <none>        443/TCP          26m
```

The kubernetes service is default, but we also have our own service first-app. We still can't see the external IP.
To see the external IP we run:

```bash
tom@tom-ubuntu:~$ minikube service first-app
|-----------|-----------|-------------|---------------------------|
| NAMESPACE |   NAME    | TARGET PORT |            URL            |
|-----------|-----------|-------------|---------------------------|
| default   | first-app |        8080 | http://192.168.49.2:32470 |
|-----------|-----------|-------------|---------------------------|
🎉  Opening service default/first-app in default browser...
tom@tom-ubuntu:~$ Opening in existing browser session.
```

Our app then starts in the browser on the IP address:

![image](https://user-images.githubusercontent.com/27693622/235322624-a6514a0a-4441-4a46-a232-cc97f61ef070.png)

We have just deployed an application using an imperative approach.
We can test the redeployment by visiting /error
Our events show that the container has restarted and then the pod has restarted:
![image](https://user-images.githubusercontent.com/27693622/235322755-e25583a7-d65a-4535-8012-83a1c0f304dc.png)

Each time the pod was restarted we started new containers.

#### Scaling

We can scale our application using the following command:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/welcome$ kubectl scale deployment/first-app --replicas=3
deployment.apps/first-app scaled
```

We now have three running pods:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/welcome$ kubectl get pods
NAME                        READY   STATUS    RESTARTS        AGE
first-app-886784874-n856k   1/1     Running   0               15s
first-app-886784874-ssbv9   1/1     Running   2 (4m21s ago)   23m
first-app-886784874-wn4zb   1/1     Running   0               15s

```

We can cause the pods to restart by visiting /error. The pods then restart to fulfil the scaling instruction:
![image](https://user-images.githubusercontent.com/27693622/235322907-8b7db092-ee00-4fbc-898f-275960724610.png)

We can also change code in our docker container and push the change to dockerhub. We can then set our image for our
deployment to our new image:

```bash
tom@tom-ubuntu:~$ kubectl set image deployment/first-app kub-first-app=tomspencerlondon/kub-first-app
```

We can then set the new image being used:

```bash
tom@tom-ubuntu:~$ kubectl set image deployment/first-app kub-first-app=tomspencerlondon/kub-first-app
```

This doesn't change our code on the running pods. We need to tag our image to ensure that it is used as the new image.
We first tag the image and then push it to docker hub. We can then set the image to the new image:

```bash
tom@tom-ubuntu:~$ kubectl set image deployment/first-app kub-first-app=tomspencerlondon/kub-first-app:2
deployment.apps/first-app image updated
```

We can see the rollout status with:

```bash
tom@tom-ubuntu:~$ kubectl rollout status deployment/first-app
deployment "first-app" successfully rolled out
```

We have now updated our application with the set image command.

If we update with a non-existing image:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl set image deployment/first
-app kub-first-app=tomspencerlondon/kub-first-app:3
deployment.apps/first-app image updated
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl rollout status deployment/first-app
Waiting for deployment "first-app" rollout to finish: 1 out of 3 new replicas have been updated...
```

The update just hangs but does not affect the other pods.
We can use:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/more-complex-docker$ kubectl get pods
NAME                         READY   STATUS         RESTARTS        AGE
first-app-78f86c8658-54fvg   1/1     Running        1 (7m49s ago)   13h
first-app-78f86c8658-nvc78   1/1     Running        1 (7m49s ago)   13h
first-app-78f86c8658-w9th2   1/1     Running        1 (7m49s ago)   13h
first-app-7d77b99977-thzpc   0/1     ErrImagePull   0               3m25s

```

to check running pods. We can see that one pod is failing.
We can now rollback the problem deployment:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/more-complex-docker$ kubectl rollout undo deployment/first-app
deployment.apps/first-app rolled back
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/more-complex-docker$ kubectl get pods
NAME                         READY   STATUS    RESTARTS        AGE
first-app-78f86c8658-54fvg   1/1     Running   1 (8m58s ago)   13h
first-app-78f86c8658-nvc78   1/1     Running   1 (8m58s ago)   13h
first-app-78f86c8658-w9th2   1/1     Running   1 (8m58s ago)   13h
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/more-complex-docker$ kubectl rollout status deployment/first-app
deployment "first-app" successfully rolled out
```

We can check the rollout history with:

```bash
tom@tom-ubuntu:~$ kubectl rollout history deployment/first-app
deployment.apps/first-app 
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
```

We can get more detail on a revision:

```bash
tom@tom-ubuntu:~$ kubectl rollout history deployment/first-app --revision 3
deployment.apps/first-app with revision #3
Pod Template:
  Labels:	app=first-app
	pod-template-hash=7d77b99977
  Containers:
   kub-first-app:
    Image:	tomspencerlondon/kub-first-app:3
    Port:	<none>
    Host Port:	<none>
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
```

To go back to a previous revision we can use:

```bash
tom@tom-ubuntu:~$ kubectl rollout undo deployment/first-app --to-revision=1
deployment.apps/first-app rolled back
```

We can delete all our work on kubernetes with:

```bash
tom@tom-ubuntu:~$ kubectl delete service first-app
service "first-app" deleted
tom@tom-ubuntu:~$ kubectl delete deployment first-app
deployment.apps "first-app" deleted
tom@tom-ubuntu:~$ kubectl get pods
NAME                        READY   STATUS        RESTARTS        AGE
first-app-886784874-7g22b   1/1     Terminating   1 (3m37s ago)   4m
first-app-886784874-clf9m   1/1     Terminating   1 (3m37s ago)   4m6s
first-app-886784874-nd5zb   1/1     Terminating   1 (3m36s ago)   4m2s
```

### Declarative Approach

Earlier we used docker compose files to define our application. We can do the same with kubernetes. We can create a
resource definition file like the following for example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app
spec:
  selector:
    matchLabels:
      app: second-dummy
  replicas: 1
  template:
    metadata:
      labels:
        app: second-dummy
    spec:
      containers:
        - name: second-node
          image: "tomspencerlondon/kub-first-app"
```

Here we define the number of instances in the deployment and the image we are referring to. This is the comparison:

| Imperative                                                             | Declarative                                                      |
|------------------------------------------------------------------------|------------------------------------------------------------------|
| kubectl create deployment ...                                          | kubectl apply -f config.yaml                                     |
| Individual commands are executed to trigger certain Kubernetes actions | A config file is defined and applied to change the desired state |
| Comparable to using docker run only                                    | Comparable to Docker Compose with compose files                  |

Now we can use configuration files without running lots of kubectl commands. First we check that our workspace is clean:
```bash
tom@tom-ubuntu:~$ kubectl get deployments
No resources found in default namespace.
tom@tom-ubuntu:~$ kubectl get pods
No resources found in default namespace.
tom@tom-ubuntu:~$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   15h
```
The only service is the default Kubernetes service. 

### Deploy with a config file
We first add a deployment.yaml file with our configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: second-app
      tier: backend
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: tomspencerlondon/kub-first-app:2
```
We have added a selector entry for the spec of the deployment. The deployment watches to see which pods it needs to control.
We then apply the configuration with:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl apply -f=deployment.yaml
deployment.apps/second-app-deployment created
```
We can check the deployment and the pod:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get deployments
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
second-app-deployment   1/1     1            1           20s
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
second-app-deployment-5b6dd555c6-w4vdg   1/1     Running   0          32s
```
Next we will declare a service for our deployment. We add a service.yaml file with the following configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: second-app
    tier: backend
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: LoadBalancer
```
We can apply this with:

```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl apply -f service.yaml
service/backend created
```
We can then list the service with:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get service
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
backend      LoadBalancer   10.109.14.67   <pending>     8080:30640/TCP   49s
kubernetes   ClusterIP      10.96.0.1      <none>        443/TCP          21h
```
We then can view the service with minikube:
```bash
minikube service backend
```
![image](https://user-images.githubusercontent.com/27693622/235367969-4ce47316-0f31-491c-b0c5-8f16d3673e71.png)

We can delete the deployment with the name of the deployment:
```bash
kubectl delete deployment second-app-deployment
```
but we can also use the configuration:
```bash
kubectl delete -f=deployment.yaml
```
This would delete the deployment. We can also have one file with all the configuration:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: second-app
    tier: backend
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: second-app
      tier: backend
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: tomspencerlondon/kub-first-app:2
```
We use dashes to separate the Deployment and Service definitions. We also use 3 dashes to separate the objects.
The Service would then continuously monitor the deployment.
To test this we can delete the deployment and service we started earlier with:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl delete -f=deployment.yaml -f=service.yaml
deployment.apps "second-app-deployment" deleted
service "backend" deleted
```
and then apply the new merged master configuration:
```bash

tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl apply -f=master-deployment.yaml
service/backend created
deployment.apps/second-app-deployment created

```

### Selectors
Alongside selector matchLabels we can use matchExpressions.
The matchExpressions available are In, NotIn and Exists.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  selector:
    #    matchLabels:
    #      app: second-app
    #      tier: backend
    matchExpressions:
      - {key: app, operator: In, values: [second-app, first-app]}
```

We can also delete by selector:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl get deployments
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
second-app-deployment   1/1     1            1           6m20s
```
We use add the label to our service.yaml and deployment.yml and rerun the deployments to give them labels. We can then 
delete the deploymnent and service with:
```bash
tom@tom-ubuntu:~/Projects/Docker-And-Kubernetes/kub-action-01-starting-setup$ kubectl delete deployments,services -l group=example
deployment.apps "second-app-deployment" deleted
service "backend" deleted
```
We can add a liveness probe for the containers to ensure that the deployment is restarted when there is an error:
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
  labels:
    group: example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: second-app
      tier: backend
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: tomspencerlondon/kub-first-app:2
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```
The liveness probe is useful as a health check to ensure that the container is running correctly. If the liveness probe fails
then the container is restarted.

There are also lots of configuration options for the container objects such as imagePullPolicy: Always, Never or IfNotPresent.
We can use Always to ensure that changes to the image with the same tag are pulled. We can use Never to ensure that the image
is never pulled. We can use IfNotPresent to ensure that the image is only pulled if it is not present on the node.

