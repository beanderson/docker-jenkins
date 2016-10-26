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
    sudo \
    && yum clean all

# Add Tini Version
ENV TINI_VERSION=v0.10.0 \
# Docker API Version
    DOCKER_API_VERSION=1.23 \
# Jenkins Version
    JENKINS_VERSION=2.26 \

    JENKINS_HOME=/var/jenkins_home \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_UC=https://updates.jenkins.io \
    COPY_REFERENCE_FILE_LOG=/var/jenkins_home/copy_reference_file.log \
    JAVA_OPTS="-Xmx4096m" \
    JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log  --webroot=/var/cache/jenkins/war"

RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins \
    && echo "jenkins  ALL=(ALL)  NOPASSWD: ALL" >> /etc/sudoers \ 
    && sed -i -e 's/Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers 

# Jenkins home directory is a volume, so can be persisted and survive image upgrades
VOLUME ["/var/jenkins_home"]

# Install tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /bin/tini
# Install Jenkins
ADD http://mirrors.jenkins-ci.org/war/$JENKINS_VERSION/jenkins.war /usr/share/jenkins/jenkins.war 

# Jenkins is run with user `jenkins`, uid = 1000 & Prep Jenkins Directories & Install Docker
RUN chmod +x /bin/tini \ 
    && mkdir -p /usr/share/jenkins/ref/init.groovy.d \
    && mkdir /var/log/jenkins \
    && mkdir /var/cache/jenkins \
    && chown -R jenkins:jenkins "$JENKINS_HOME" \
    && chown -R jenkins:jenkins /usr/share/jenkins/ref \
    && chown -R jenkins:jenkins /usr/share/jenkins/ref/init.groovy.d \
    && chown -R jenkins:jenkins /usr/share/jenkins/jenkins.war \
    && chown -R jenkins:jenkins /var/log/jenkins \
    && chown -R jenkins:jenkins /var/cache/jenkins \
    && touch /var/run/docker.sock \
    && chown -R jenkins:jenkins /var/run/docker.sock \
    && curl -fsSL https://get.docker.com/ | sh \
    && usermod -aG docker jenkins

# Expose Ports for web and slave agents
EXPOSE 8080 50000

USER jenkins

COPY files/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
COPY files/bin /usr/local/bin/

RUN /usr/local/bin/install-plugins.sh active-directory ant blueocean bouncycastle-api build-timeout copyartifact credentials-binding docker-build-publish docker-build-step docker-plugin email-ext envinject github-organization-folder gradle jclouds-jenkins jobConfigHistory kubernetes matrix-auth parameterized-trigger ssh timestamper workflow-aggregator ws-cleanup \ 
    && echo $JENKINS_VERSION > $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion \
    && echo $JENKINS_VERSION > $JENKINS_HOME/jenkins.install.UpgradeWizard.state

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

