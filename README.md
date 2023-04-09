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
