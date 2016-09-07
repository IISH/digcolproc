#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# provision.sh
#
# Usage: ./provision.sh [operating system] [environment=development|[what you would like]]
#
#
# Ensure that the packager manager's latest repository settings are up to date.
#
# This script will set an empty file '/opt/firstrun'
# Once there, future vagrant provisioning skip the update steps.
# Remove the file '/opt/firstrun' to repeat the update.
#

OPERATING_SYSTEM=$1
if [ -z "$OPERATING_SYSTEM" ] ; then
    echo "Operating system not specified"
    exit 1
fi

ENVIRONMENT=$2
if [ -z "$ENVIRONMENT" ] ; then
    ENVIRONMENT="development"
    echo "Environment not specified. Assuming ${ENVIRONMENT}"
fi


# Tell:
echo "OPERATING_SYSTEM=${OPERATING_SYSTEM}"
echo "ENVIRONMENT=${ENVIRONMENT}"


WD="/opt"


# puppet_config
# Set the puppet config to avoid warnings about deprecated templates.
function puppet_config {
    echo "\nDEBUG: create /etc/puppet/puppet.conf file\n"
    echo "[main]
    environment=development
    factpath=/lib/facter
    logdir=/var/log/puppet
    rundir=/var/run/puppet
    ssldir=/var/lib/puppet/ssl
    vardir=/var/lib/puppet

    [agent]
    allow_duplicate_certs=true
    masterport=443
    report=false
    server=puppetmaster.socialhistoryservices.org

    [master]
    # These are needed when the puppetmaster is run by passenger
    # and can safely be removed if webrick is used.
    ssl_client_header = SSL_CLIENT_S_DN
    ssl_client_verify_header = SSL_CLIENT_VERIFY" > /etc/puppet/puppet.conf
}



function puppet_run {
    echo "\nDEBUG: Puppet agent\n"
    puppet agent -t --waitforcert 10
}



function mountit {
    modprobe vboxsf
    mount -t vboxsf -o uid=`id -u vagrant`,gid=`getent group vagrant | cut -d: -f3` usr_bin_digcolproc /usr/bin/digcolproc
    mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` usr_bin_digcolproc /usr/bin/digcolproc
}



function main {
    if [ ! -d "$WD" ] ; then
      mkdir -p "$WD"
    fi
    cd "$WD"


    # We will only update and install in the first provisioning step.
    # If ever you need to update again
    FIRSTRUN="${WD}/firstrun"
    if [ ! -f "$FIRSTRUN" ] ; then

        # Before we continue let us ensure we have puppet and run the latests packages at the first run.
        case "$OPERATING_SYSTEM" in
            centos-6)
                rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
                yum -y update
                yum -y install puppet
            ;;
            ubuntu-12|precise)
                wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
                dpkg -i puppetlabs-release-precise.deb
                apt-get -y update
                apt-get -y install puppet
            ;;
            ubuntu-14|trusty)
                wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
                dpkg -i puppetlabs-release-trusty.deb
                apt-get -y update
                apt-get -y install puppet
            ;;
            ubuntu-15|vivid)
                wget https://apt.puppetlabs.com/puppetlabs-release-vivid.deb
                dpkg -i puppetlabs-release-vivid.deb
                apt-get -y update
                apt-get -y install puppet
            ;;
            *)
                echo "Operating system ${OPERATING_SYSTEM} not supported."
                exit 1
            ;;
        esac


        puppet resource package puppet ensure=latest

        puppet_config
        puppet_run

        touch "$FIRSTRUN"
    else
        echo "Repositories are already updated and puppet modules are installed. To update and reinstall, remove the file ${FIRSTRUN}"
    fi

    mountit
}

main

exit 0
