#!/usr/bin/env groovy

properties([[$class: 'GitLabConnectionProperty', gitLabConnection: 'gitlab']])

node('centos7') {
  docker.withRegistry('https://quay.io', 'quay-bryan-test') {
    def jenkinsImage = docker.image("prsn/jenkins:master-${env.BRANCH_NAME}")
    
    stage('Prep') {
      currentBuild.displayName="Prep"
      checkout scm
    }

    stage('Build') {
      currentBuild.displayName="Build"
      docker.build(jenkinsImage.id, '.')
    }
    
    stage('Test') {
      currentBuild.displayName="Test"
      jenkinsImage.inside {
        sh 'ls'
      }
    }

    stage('Accept') {
      currentBuild.displayName="Accept"
      input 'Image Acceptable?'
    }

    stage('Publish') {
      currentBuild.displayName="Publish"
      jenkinsImage.push()
    }
  }
}



   