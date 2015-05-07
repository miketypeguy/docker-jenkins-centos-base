FROM centos:centos6
MAINTAINER devops@signiant.com

# Install EPEL
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# Install a base set of packages
COPY yum.packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN yum install -y -q `cat /tmp/yum.packages.list`

# Install PIP - useful everywhere
RUN /usr/bin/curl -O https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

# Install the AWS CLI - useful everywhere
RUN pip install awscli


