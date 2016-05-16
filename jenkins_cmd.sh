#!/bin/bash

# Known issues:
# - add mailcatcher to Procfile
# - foreman uses PORT=5000 by default, all templates uses 3000 instead
# - no final git commit
#
# Requested features:
# - bower
# * simplecov
# - rubocop
# - rails_best_practices

LOCAL_RVM_PATH="$HOME/.rvm/scripts/rvm"
GLOBAL_RVM_PATH="/usr/local/rvm/scripts/rvm"
CURRENT_PATH=`pwd`

# Load RVM into a shell session *as a function*
if [[ -s $LOCAL_RVM_PATH ]] ; then
  # First try to load from a user install
  source $LOCAL_RVM_PATH
elif [[ -s $GLOBAL_RVM_PATH ]] ; then
  # Then try to load from a root install
  source $GLOBAL_RVM_PATH
else
  printf "ERROR: An RVM installation was not found. You must install RVM first.\n"
  exit 1
fi

printf "Please provide Project name. This name will be used as a prefix for jenkins jobs:\n"
read -p "Project name [myapp]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-myapp}

printf "Please provide ruby version you are using in your project application.\n"
read -p "Ruby Version [2.2.2]: " RUBY_VERSION
RUBY_VERSION=${RUBY_VERSION:-2.2.2}

printf "Please provide ruby gemset you are using in your project application.\n"
printf "To have Jenkins job run correctly you may need to open generated job Configure page, goto Build Environment section. And set checkbox ""Run the build in a RVM-managed environment"". Also it will require to set ruby version@gemset in the Implementation variable below the checkbox.\n"
read -p "Ruby gemset [rpsk]: " RUBY_GEMSET
RUBY_GEMSET=${RUBY_GEMSET:-rpsk}
printf "Please use ""$RUBY_VERSION@$RUBY_GEMSET"" for the Implementation variable below the checkbox.\n"

DEFAULT_REPO_URL="git@github.com:some_github_user/$PROJECT_NAME.git"
DEFAULT_REPO_URL="git@github.com:akyrylenko/testgenerator.git" # for development
printf "Please provide project git repository address.\n"
read -p "Git repository address: [$DEFAULT_REPO_URL] " REPO_URL
REPO_URL=${REPO_URL:-$DEFAULT_REPO_URL}

# If you are using git repository domain for the first time on the requested Jenkins CI Server
# you may need to pass host verification for it on the jenkins server.
# E.g. you need to get access from the jenkins server to bitbucket repo.
# Than you require to sign in to the jenkins host via SSH as jenkins user and run
#   git ls-remote -h  git@bitbucket.org:repousername/reponame.git HEAD

# Also you'll may need to grant access from jenkins to the repository by adding jenkins public key to the repouser settings

DEFAULT_GITHUB_PATH="some_github_user/$PROJECT_NAME.git"
DEFAULT_GITHUB_PATH="akyrylenko/testgenerator.git" # for development

set -f
oldifs="$IFS"
IFS=':'; arrayIN=($REPO_URL)
IFS="$oldifs"
DEFAULT_GITHUB_PATH="${arrayIN[1]}"
echo "$DEFAULT_GITHUB_PATH"
set +f

printf "Please provide git repository path. Default is taken from the Git url but you can update it.\n"
read -p "Git repository path: [$DEFAULT_GITHUB_PATH] " GITHUB_PATH
GITHUB_PATH=${GITHUB_PATH:-$DEFAULT_GITHUB_PATH}

DEFAULT_JENKINS_URL="http://localhost:8080"
#DEFAULT_JENKINS_URL="http://jenkins.gera-it.com" # for development
printf "Please provide jenkins address\n"
read -p "Jenkins Address: [$DEFAULT_JENKINS_URL] " JENKINS_URL
JENKINS_URL=${JENKINS_URL:-$DEFAULT_JENKINS_URL}

DEFAULT_JENKINS_USER_ID=""
#DEFAULT_JENKINS_USER_ID="akyrylenko" # for development
printf "Please provide jenkins UserID. It can be taken from the Jenkins User Profile page\n"
printf "You can access it by User Dropdown in the top right corner of the Jenkins UI\n"
read -p "Jenkins UserID: [$DEFAULT_JENKINS_USER_ID] " JENKINS_USER_ID
JENKINS_USER_ID=${JENKINS_USER_ID:-$DEFAULT_JENKINS_USER_ID}

DEFAULT_JENKINS_API_TOKEN=""
#DEFAULT_JENKINS_API_TOKEN="ab5495cf6b05e88a66b2c9fd6eb363d1" # for development
printf "Please provide jenkins API Token. It is required if you have setup security access to the CI server. It can be taken from the jenkins web UI\n"
read -p "Please provide jenkins API Token: [$DEFAULT_JENKINS_API_TOKEN] " JENKINS_API_TOKEN
JENKINS_API_TOKEN=${JENKINS_API_TOKEN:-$DEFAULT_JENKINS_API_TOKEN}

DEFAULT_USER_FULLNAME="Firstname Lastname"
DEFAULT_USER_FULLNAME="Andriy Kyrylenko" # for development
DEFAULT_USER_FULLNAME="Jenkins User" # for development
printf "Please provide user fullname for github identifiing in jenkins run.\n"
read -p "Git user fullname: [$DEFAULT_USER_FULLNAME] " USERNAME
USER_FULLNAME=${USER_FULLNAME:-$DEFAULT_USER_FULLNAME}

DEFAULT_USER_EMAIL="user@example.com"
DEFAULT_USER_EMAIL="andriy.kyrylenko@gmail.com" # for development
DEFAULT_USER_EMAIL="jenkins@jenkins.local" # for development
read -p "Please provide user email for github identifiing in jenkins run: [$DEFAULT_USER_EMAIL] " USER_EMAIL
USER_EMAIL=${USER_EMAIL:-$DEFAULT_USER_EMAIL}

#
# #######################
# # Prerequisites start #
# #######################
#

rvm install $RUBY_VERSION
rvm use ruby-$RUBY_VERSION@$RUBY_GEMSET --ruby-version --create

printf "Installing jenkins_api_client...\n"
gem install jenkins_api_client --no-ri --no-rdoc

# Script that should be run from rpsk project folder

ruby ./jenkins_cmd.rb --project-name $PROJECT_NAME --jenkins-url $JENKINS_URL --jenkins-user-id $JENKINS_USER_ID --jenkins-api-token $JENKINS_API_TOKEN --ruby-version $RUBY_VERSION --ruby-gemset $RUBY_GEMSET --github-url $REPO_URL --github-path $GITHUB_PATH --user-fullname $USER_FULLNAME --user-email $USER_EMAIL
