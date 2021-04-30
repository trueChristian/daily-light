#! /bin/bash

# DEFAULTS/GLOBALS
GPG_KEY=""
GPG_USER=""
SSH_KEY=""
SSH_PUB=""
GIT_USER=""
GIT_EMAIL=""

# check if we have options
while :; do
  case $1 in
  --gpg-key) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      GPG_KEY=$2
      shift
    else
      echo 'ERROR: "--gpg-key" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --gpg-key=?*)
    GPG_KEY=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --gpg-key=) # Handle the case of an empty --gpg-key=
    echo 'ERROR: "--gpg-key" requires a non-empty option argument.'
    exit 1
    ;;
  --gpg-user) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      GPG_USER=$2
      shift
    else
      echo 'ERROR: "--gpg-user" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --gpg-user=?*)
    GPG_USER=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --gpg-user=) # Handle the case of an empty --gpg-user=
    echo 'ERROR: "--gpg-user" requires a non-empty option argument.'
    exit 1
    ;;
  --ssh-key) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      SSH_KEY=$2
      shift
    else
      echo 'ERROR: "--ssh-key" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --ssh-key=?*)
    SSH_KEY=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --ssh-key=) # Handle the case of an empty --ssh-key=
    echo 'ERROR: "--ssh-key" requires a non-empty option argument.'
    exit 1
    ;;
  --ssh-pub) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      SSH_PUB=$2
      shift
    else
      echo 'ERROR: "--ssh-pub" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --ssh-pub=?*)
    SSH_PUB=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --ssh-pub=) # Handle the case of an empty --ssh-pub=
    echo 'ERROR: "--ssh-pub" requires a non-empty option argument.'
    exit 1
    ;;
  --git-user) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      GIT_USER=$2
      shift
    else
      echo 'ERROR: "--git-user" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --git-user=?*)
    GIT_USER=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --git-user=) # Handle the case of an empty --git-user=
    echo 'ERROR: "--git-user" requires a non-empty option argument.'
    exit 1
    ;;
  --git-email) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      GIT_EMAIL=$2
      shift
    else
      echo 'ERROR: "--git-email" requires a non-empty option argument.'
      exit 1
    fi
    ;;
  --git-email=?*)
    GIT_EMAIL=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  --git-email=) # Handle the case of an empty --git-email=
    echo 'ERROR: "--git-email" requires a non-empty option argument.'
    exit 1
    ;;
  *) # Default case: No more options, so break out of the loop.
    break ;;
  esac
  shift
done

# We must sign all git push events
if [ -z "${GPG_KEY}" ]; then
  echo >&2 "The GPG_KEY:${GPG_KEY} is not set. Aborting."
  exit 1
else
  # place the secret in the open to github... where it is anyway.
  echo "${GPG_KEY}" >robot.asc
  # add the key to the system
  gpg --import robot.asc
fi

# To set the github signingkey we need to get the gpg key id with the key user name
if [ -z "${GPG_USER}" ]; then
  echo >&2 "The GPG_USER:${GPG_USER} is not set. Aborting."
  exit 1
else
  # get the gpg signingkey ID
  git_signingkey=$(gpg --list-signatures --with-colons | grep 'sig' | grep "${GPG_USER}" | head -n 1 | cut -d':' -f5)
fi

# make the ssh dir
mkdir -p ~/.ssh

# we need to set the SSH key to push/pull to/from github
if [ -z "${SSH_KEY}" ]; then
  echo >&2 "The SSH_KEY is not set. Aborting."
  exit 1
fi
if [ -z "${SSH_PUB}" ]; then
  echo >&2 "The SSH_PUB is not set. Aborting."
  exit 1
fi

# move the keys into place (check the type!)
echo "${SSH_KEY}" >~/.ssh/id_ed25519
echo "${SSH_PUB}" >~/.ssh/id_ed25519.pub

# set the protection of the key files
chmod 400 ~/.ssh/id_ed25519
chmod 400 ~/.ssh/id_ed25519.pub

# We need the git user name/email set to access github
if [ -z "${GIT_USER}" ]; then
  echo >&2 "The GIT_USER is not set. Aborting."
  exit 1
fi
if [ -z "${GIT_EMAIL}" ]; then
  echo >&2 "The GIT_EMAIL is not set. Aborting."
  exit 1
fi

# set the github user details
git config --global user.name "${GIT_USER}"
git config --global user.email "${GIT_EMAIL}"
git config --global user.signingkey "$git_signingkey"
