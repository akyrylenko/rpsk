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

read -p "Please provide base dir for project [$HOME/Projects] " BASE_DIR
BASE_DIR=${BASE_DIR:-$HOME/Projects}

read -p "Please provide project name [myapp]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-myapp}

read -p "Please provide ruby version [2.2.2]: " RUBY_VERSION
RUBY_VERSION=${RUBY_VERSION:-2.2.2}

read -p "Please provide staging server address: [$PROJECT_NAME.your-domain.com] " STAGE_ADDR
STAGE_ADDR=${STAGE_ADDR:-$PROJECT_NAME.your-domain.com}

read -p "Please provide staging server application user: [$PROJECT_NAME] " STAGE_USER
STAGE_USER=${STAGE_USER:-$PROJECT_NAME}

read -p "Please provide initial provisioning user name: [root] " INITIAL_USER
INITIAL_USER=${INITIAL_USER:-root}

read -p "Please provide git repository address: [git@github.com:some_github_user/$PROJECT_NAME.git] " REPO_URL
REPO_URL=${REPO_URL:-git@github.com:some_github_user/$PROJECT_NAME.git}

STAGE_URL="$STAGE_USER@$STAGE_ADDR"

read -p "Please provide path to your public key: [$HOME/.ssh/id_rsa.pub] " PUBKEY_PATH
PUBKEY_PATH=${PUBKEY_PATH:-$HOME/.ssh/id_rsa.pub}

# Jenkins parameters

printf "Please provide ruby gemset you are using in your project application.\n"
printf "To have Jenkins job run correctly you may need to open generated job Configure page, goto Build Environment section. And set checkbox ""Run the build in a RVM-managed environment"". Also it will require to set ruby version@gemset in the Implementation variable below the checkbox.\n"
read -p "Ruby gemset [myapp]: " RUBY_GEMSET
RUBY_GEMSET=${RUBY_GEMSET:-myapp}
printf "Please use ""$RUBY_VERSION@$RUBY_GEMSET"" for the Implementation variable below the checkbox.\n"

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

BASE_DIR="$BASE_DIR/$PROJECT_NAME"
mkdir -p $BASE_DIR
cd $BASE_DIR

rvm install $RUBY_VERSION

#
# #####################
# # Prerequisites end #
# #####################
#

#
# ####################################
# # Provisioning project setup start #
# ####################################
#

printf "Creating provisioning project...\n"
PP_NAME="provisioning"
PP_DIR="$BASE_DIR/$PP_NAME"

PP_TEMPLATES_DIR="$CURRENT_PATH/templates/ansible"

cp -r $PP_TEMPLATES_DIR $PP_DIR
sed -e "s/%STAGE_ADDR%/$STAGE_ADDR/g" $PP_NAME/inventories/staging.template > $PP_DIR/inventories/staging
rm $PP_DIR/inventories/staging.template

sed -e "s/%PUBKEY%/$(cat $PUBKEY_PATH | sed -e 's/\//\\\//g')/g" -e "s/%STAGE_USER%/$STAGE_USER/g" -e "s/%PROJECT_NAME%/$PROJECT_NAME/g" -e "s/%STAGE_ADDR%/$STAGE_ADDR/g" -e "s/%RUBY_VERSION%/$RUBY_VERSION/g" -e "s/%INITIAL_USER%/$INITIAL_USER/g" $PP_DIR/group_vars/staging.template > $PP_DIR/group_vars/staging
rm $PP_DIR/group_vars/staging.template

cd  $PP_DIR
git init
git add .
git commit -qm "initial commit"

printf "$PP_NAME project created...\n"
printf "Please review $PP_DIR/group_vars/staging and change default passwords\n"

#
# ##################################
# # Provisioning project setup end #
# ##################################
#

#
# ##################################
# # Deployment project setup start #
# ##################################
#

printf "Creating deployment project...\n"

DP_NAME=deploy
DP_DIR="$BASE_DIR/$DP_NAME"
DP_GEMSET="$PROJECT_NAME-deploy"
mkdir -p $DP_DIR

DP_TEMPLATES_DIR="$CURRENT_PATH/templates/capistrano"
cp $DP_TEMPLATES_DIR/Gemfile $DP_DIR
cp $DP_TEMPLATES_DIR/Capfile $DP_DIR
mkdir -p $DP_DIR/config/deploy
sed -e "s/%PROJECT_NAME%/$PROJECT_NAME/g" -e "s/%REPO_URL%/$(echo $REPO_URL | sed -e 's/\//\\\//g')/g" $DP_TEMPLATES_DIR/deploy.rb.template > $DP_DIR/config/deploy.rb
sed -e "s/%PROJECT_NAME%/$PROJECT_NAME/g" -e "s/%STAGE_URL%/$STAGE_URL/g" $DP_TEMPLATES_DIR/staging.rb.template > $DP_DIR/config/deploy/staging.rb

printf "Creating gemset...\n"
cd $DP_DIR
rvm use ruby-$RUBY_VERSION@$DP_GEMSET --ruby-version --create
echo $DP_GEMSET > .ruby-gemset
gem install bundler --no-ri --no-rdoc
bundle

printf "Initializing git repository...\n"
echo '.ruby-gemset' > .gitignore
git init
git add .
git commit -qm 'initial commit'

cd $CURRENT_PATH
printf "$DP_NAME project created...\n"

#
# #################################
# # Deployment project setup end  #
# #################################
#

AP_NAME=app
AP_DIR="$BASE_DIR/$AP_NAME"
mkdir -p $AP_DIR
cd $AP_DIR
AP_GEMSET="$PROJECT_NAME-app"

if [[ -f ".ruby-version" ]] ; then
  printf "Using existing gemset...\n"
else
  printf "Creating gemset...\n"
  rvm use ruby-$RUBY_VERSION@$AP_GEMSET --ruby-version --create
fi

printf "Installing rails...\n"
gem install rails --no-ri --no-rdoc

printf "Installing rails_apps_composer...\n"
gem install rails_apps_composer

if [[ -f $CURRENT_PATH/defaults.yml ]] ; then
  rails_apps_composer new . \
    --recipe_dirs=$CURRENT_PATH/recipes \
    --defaults=$CURRENT_PATH/defaults.yml \
    --quiet \
    --verbose
else
  rails_apps_composer new . \
    --recipe_dirs=$CURRENT_PATH/recipes \
    --quiet \
    --verbose
fi

# TODO for future purposes
# rails_apps_composer template gera.rb \
#   --recipe_dirs=$CURRENT_PATH/recipes \
#   --defaults=$CURRENT_PATH/$DEFAULTS \
#   --quiet \
#   --verbose

# Jenkins config file copying
cd $AP_DIR
mkdir config/deploy
mkdir config/deploy/ci
cp config/database.yml config/deploy/ci/database.yml

# Update Rakefile for ci tasks
sed '6 i\
if (ENV['RAILS_ENV']=='test' || ENV['RAILS_ENV']=='development') \
  task :rspec => 'ci:setup:rspec' \
end \
' Rakefile > Rakefile.tmp1
sed '4 i\
require('ci/reporter/rake/rspec') if (ENV['RAILS_ENV']=='test' || ENV['RAILS_ENV']=='development') \
' Rakefile.tmp1 > Rakefile.tmp2
cp Rakefile.tmp2 Rakefile
rm Rakefile.tmp*
cat Rakefile

git remote add origin $REPO_URL
git push -u origin master

cd $CURRENT_PATH
printf "\n"
printf "Note: Please configure your staging smtp getaway and other staging vars in $CURRENT_PATH/provisioning/group_vars/staging [Ansible] \n"


printf "Installing jenkins_api_client...\n"
gem install jenkins_api_client --no-ri --no-rdoc

# Script that should be run from rpsk project folder

ruby ./jenkins_cmd.rb --project-name $PROJECT_NAME --jenkins-url $JENKINS_URL --jenkins-user-id $JENKINS_USER_ID --jenkins-api-token $JENKINS_API_TOKEN --ruby-version $RUBY_VERSION --ruby-gemset $RUBY_GEMSET --github-url $REPO_URL --github-path $GITHUB_PATH --user-fullname $USER_FULLNAME --user-email $USER_EMAIL
printf "\n"
printf "Note: Please make sure you have config/deploy/ci/database.yml configuration file so jenkins will use it during runnins application. Please contact with your jenkins host admin to get right credentials for access DB. \n"
