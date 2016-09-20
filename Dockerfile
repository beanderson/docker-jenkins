FROM centos:7

MAINTAINER AIDevOps

RUN yum update -y \
    && yum clean all \
    && yum install -y \
    ca-certificates \
    curl \
    wget \
    git \
    procps \
    openssh-server \
    bzip2 \
    unzip \
    zip \
    java-1.8.0-openjdk \   
    && yum clean all

# Add Tini
ENV TINI_VERSION v0.10.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /bin/tini
RUN chmod +x /bin/tini

# SET Jenkins Environment Variables
ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
ENV JENKINS_VERSION 2.23
ENV JENKINS_SHA 07a2e3e4ace728fdbcc823f46068d2f8cc3cb97b
ENV JENKINS_UC https://updates.jenkins.io
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log
ENV JAVA_OPTS="-Xmx8192m"
ENV JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log  --webroot=/var/cache/jenkins/war"

# Jenkins is run with user `jenkins`, uid = 1000
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins
RUN echo "jenkins  ALL=(ALL)  ALL" >> /etc/sudoers

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

ADD http://mirrors.jenkins-ci.org/war/$JENKINS_VERSION/jenkins.war /usr/share/jenkins/jenkins.war 
# Install Jenkins
# RUN curl -fsSL http://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/$JENKINS_VERSION/jenkins-war-$JENKINS_VERSION.war -o /usr/share/jenkins/jenkins.war \
#  && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha1sum -c -

# Prep Jenkins Directories
RUN mkdir /var/log/jenkins \
    && mkdir /var/cache/jenkins \
    && chown -R jenkins:jenkins "$JENKINS_HOME" \
    && chown -R jenkins:jenkins /usr/share/jenkins/ref \
    && chown -R jenkins:jenkins /usr/share/jenkins/jenkins.war \
    && chown -R jenkins:jenkins /var/log/jenkins \
    && chown -R jenkins:jenkins /var/cache/jenkins

# Expose Ports for web and slave agents
EXPOSE 8080
EXPOSE 50000

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

USER jenkins

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh

COPY install-plugins.sh /usr/local/bin/install-plugins.sh
COPY plugins.txt /plugins.txt
RUN /usr/local/bin/install-plugins.sh workflow-support jclouds-jenkins ssh-slaves token-macro durable-task docker kubernetes cloudbees-folder active-directory blueocean workflow-aggregator

RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

