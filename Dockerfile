FROM centos:centos6.6
MAINTAINER devops@signiant.com

# Install wget which we need later
RUN yum install -y wget

# Install EPEL
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# Install the repoforge repo (needed for updated git)
RUN wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm -O /tmp/repoforge.rpm
RUN yum install -y /tmp/repoforge.rpm
RUN rm -f /tmp/repoforge.rpm

# Install a base set of packages from the default repo
COPY yum-packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN yum install -y -q `cat /tmp/yum.packages.list`

# Install packages from the repoforge repo
COPY repoforge-packages.list /tmp/repoforge.packages.list
RUN chmod +r /tmp/repoforge.packages.list
RUN yum install -y -q --enablerepo=rpmforge-extras `cat /tmp/repoforge.packages.list`

# Install PIP - useful everywhere
RUN /usr/bin/curl -O https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

# Install the AWS CLI - useful everywhere
RUN pip install awscli

# make sure we're running latest of everything
RUN yum update -y

# Update node and npm
RUN npm install -g npm
RUN npm install -g bower
RUN npm install -g grunt
RUN npm install -g grunt-cli

# We have to use this fixed version otherwise we get fatal error: socket hang up errors
RUN npm install -g grunt-connect-proxy@0.1.10

# Add our bldmgr user
ENV BUILD_USER bldmgr
ENV BUILD_USER_ID 10012
ENV BUILD_USER_GROUP users

RUN adduser -u $BUILD_USER_ID -g $BUILD_USER_GROUP $BUILD_USER
RUN passwd -f -u $BUILD_USER

# Create the folder we use for Jenkins workspaces across all nodes
RUN mkdir -p /var/lib/jenkins
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /var/lib/jenkins

# Add in our common jenkins node tools for bldmgr
COPY jenkins_nodes /home/$BUILD_USER/jenkins_nodes

# Make our build user require no tty
RUN echo "Defaults:$BUILD_USER !requiretty" >> /etc/sudoers

# Add user to sudoers with NOPASSWD
RUN echo "$BUILD_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install and configure SSHD (needed by the Jenkins slave-on-demand plugin)
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -ri 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd
RUN sed -ri 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config
RUN mkdir -p /home/$BUILD_USER/.ssh
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER
RUN chmod 700 /home/$BUILD_USER/.ssh
