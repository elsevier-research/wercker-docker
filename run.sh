#!/bin/bash

set +e
set -o noglob


#
# Set Colors
#

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#
# Headers and Logging
#

underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
success() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}


type_exists() {
  if [ $(type -P $1) ]; then
    return 0
  fi
  return 1
}

# Check variables
if [ -z "$WERCKER_DOCKER_IMAGE" ]; then
  info "Please set the 'image' variable"
  exit 1
fi

if [ -z "$WERCKER_DOCKER_USERNAME" ]; then
  error "Please set the 'username' variable"
  exit 1
fi

if [ -z "$WERCKER_DOCKER_PASSWORD" ]; then
  error "Please set the 'password' variable"
  exit 1
fi

if [ -z "$WERCKER_DOCKER_EMAIL" ]; then
  error "Please set the 'email' variable"
  exit 1
fi


# Check Docker is installed
if ! type_exists 'docker'; then
  error "Docker is not installed on this box."
  info "Please use a box with docker installed : http://devcenter.wercker.com/articles/docker"
  exit 1
fi


# Variables
IMAGE="$WERCKER_DOCKER_IMAGE"
IMAGE_PATH=${WERCKER_DOCKER_PATH:-.}
TAGS=${WERCKER_DOCKER_TAGS:-latest}
REGISTRY="$WERCKER_DOCKER_REGISTRY"
USERNAME="$WERCKER_DOCKER_USERNAME"
PASSWORD="$WERCKER_DOCKER_PASSWORD"
EMAIL="$WERCKER_DOCKER_EMAIL"

set -e
# ----- Building image -----
# see documentation https://docs.docker.com/reference/commandline/cli/#build
# ---------------------------
h1 "Step 1: Building image"

# Check a Dockerfile is present
if [ ! -f "$IMAGE_PATH/Dockerfile" ]; then
  error "No Dockerfile found in folder $IMAGE_PATH."
  info "Please create a Dockerfile : https://docs.docker.com/reference/builder/"
  exit 1
fi


DOCKER_BUILD="docker build -t $IMAGE $IMAGE_PATH"
info "$DOCKER_BUILD"
DOCKER_BUILD_OUTPUT=$($DOCKER_BUILD)

if [ $? -ne 0 ];then
  warn $DOCKER_BUILD_OUTPUT
  fail "Building image $IMAGE failed"
else
  success "Building image $IMAGE succeeded"
fi

# ----- Tagging image(s) -----
# see documentation https://docs.docker.com/reference/commandline/cli/#tag
# ---------------------------
TAGS=$(echo $TAGS | sed 's/,/ /g')
IMAGES=""

h1 "Step 2: Tagging image(s)"

for TAG in $TAGS
do
  if [ -n "$REGISTRY" ]; then
     IMAGE_TAG="$REGISTRY/$USERNAME/$IMAGE:$TAG"
  else
     IMAGE_TAG="$USERNAME/$IMAGE:$TAG"
  fi

  DOCKER_TAG="docker tag $IMAGE $IMAGE_TAG"
  info "$DOCKER_TAG"

  DOCKER_TAG_OUTPUT=$($DOCKER_TAG)
  if [ $? -ne 0 ]; then
    warn "$DOCKER_TAG_OUTPUT"
    error "Tagging image $IMAGE to $IMAGE_TAG failed"
    exit 1
  else
    success "Tagging image $IMAGE to $IMAGE_TAG succeeded";
  fi
  IMAGES="$IMAGES,$IMAGE_TAG"
done

# ----- Pushing image(s) -----
# see documentation :
#  - https://docs.docker.com/reference/commandline/cli/#login
#  - https://docs.docker.com/reference/commandline/cli/#push
#  - https://docs.docker.com/reference/commandline/cli/#logout
# ---------------------------
IMAGES=$(echo $IMAGES | sed 's/,/ /g')

h1 "Step 3: Pushing image(s)"

# Login to the registry
h2 "Login to the Docker registry"

DOCKER_LOGIN="docker login --username $USERNAME --password $PASSWORD --email $EMAIL $REGISTRY"
info "docker login --username $USERNAME --password ******* --email $EMAIL $REGISTRY"
DOCKER_LOGIN_OUTPUT=$($DOCKER_LOGIN)

if [ $? -ne 0 ]; then
  warn "$DOCKER_LOGIN_OUTPUT"
  error "Login to Docker registry $REGISTRY failed"
  exit 1
else
  success "Login to Docker registry $REGISTRY succeeded";
fi

# Push the docker image
h2 "Pushing image to Docker registry"

for IMAGE in $IMAGES
do
  DOCKER_PUSH="docker push $IMAGE"
  info "$DOCKER_PUSH"
  DOCKER_PUSH_OUTPUT=$($DOCKER_PUSH)

  if [ $? -ne 0 ];then
    warn $DOCKER_PUSH_OUTPUT
    error "Pushing image $IMAGE failed";
  else
    success "Pushing image $IMAGE succeeded";
  fi

done

# Logout from the registry
h2 "Logout from the docker registry"
DOCKER_LOGOUT="docker logout $REGISTRY"
DOCKER_LOGOUT_OUTPUT=$($DOCKER_LOGOUT)

if [ $? -ne 0 ]; then
  warn "$DOCKER_LOGOUT_OUTPUT"
  error "Logout from Docker registry $REGISTRY failed"
  exit 1
else
  success "Logout from Docker registry $REGISTRY succeeded"
fi