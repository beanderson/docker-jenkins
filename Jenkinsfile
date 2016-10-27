#!/usr/bin/env groovy

node('centos7') {
  docker.withRegistry('https://quay.io', 'quay-bryan-test') {
    def jenkinsImage = docker.image("prsn/jenkins:master-${env.BRANCH_NAME}")

    // slackSend "Build Started - ${env.JOB_NAME} ${env.BUILD_NUMBER}  ()"
    
    stage('Prep') {
      currentBuild.displayName="Prep"
      checkout scm
      updateGitlabCommitStatus state: 'running'
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
      updateGitlabCommitStatus state: 'success'
    }
  }
}



   