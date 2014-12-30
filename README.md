Wercker step for Docker
=======================

This wercker step allows to [build](https://docs.docker.com/reference/commandline/cli/#build) a project as a Docker image and push the image created in a [Docker](https://docs.docker.com/reference/commandline/cli/#push) registry.

This step must be used with a wercker box built with [Docker Support](http://devcenter.wercker.com/articles/docker).

## Docker integration workflow

To build and push a Docker image, the Wercker step follow this steps :

#### Step 1 : [Building image](https://docs.docker.com/reference/commandline/cli/#build)

The following configuration allows to setup this step :

* `image` (required): Image to push to the registry
* `path` (optional): The build context path. By default: _._


#### Step 2 : [Tagging image](https://docs.docker.com/reference/commandline/cli/#tag)

The following configuration allows to setup this step :

* `tags` (optional): A comma separated list of tags. Each tagged images will be pushed. By default: _latest_

#### Step 3 : [Pushing image(s)](https://docs.docker.com/reference/commandline/cli/#push)

The following configuration allows to setup this step :

* `registry` (optional) Docker registry server, if no server is specified "https://index.docker.io/v1/" is the default.
* `username` (required) Username needed to login to the Docker registry
* `password` (required) Password needed to login to the Docker registry
* `email` (required) Email needed to login to the Docker registry

## Example


The following example build and push a docker image to a private Docker registry :

```
deploy:
  steps:
  ...
    - nhuray/wercker-docker:
        image: myimage
        tags: ${WERCKER_GIT_COMMIT:0:7},latest
        registry: tutum.co
        email: nicolas.huray@gmail.com
        password: *****
        username: nhuray
```
