#!/bin/bash

cd /vagrant

apt-get update && apt-get upgrade

apt-get install python3 python-virtualenv virtualenvwrapper

# Source virtualenv wrapper
if [ -f /etc/bash_completion.d/virtualenvwrapper ]; then
	source /etc/bash_completion.d/virtualenvwrapper
else
	exit 99
fi

# Create the virtualenv
mkvirtualenv --python=/usr/bin/python3 terrapin-web-env
if [ $? -ne 0 ]; then
	exit 98
fi

# Install our projects dependencies
PIP_COMMAND=/home/vagrant/.virtualenvs/terrapin-web-env/bin/pip
$PIP_COMMAND install -r /vagrant/requirements.txt
if [ $? -ne 0 ]; then
	exit 97
fi

# Make bash save history after every line and erase dups :
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Add these handly lines to our bashrc to save us some typing
echo "workon terrapin-web-env" >> /home/vagrant/.bashrc
echo "cd /vagrant"         >> /home/vagrant/.bashrc
