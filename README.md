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





