#!/usr/bin/env groovy

node('centos7') {

  docker.withRegistry('https://quay.io', 'quay-bryan-test') {

    def jenkinsImage = docker.image.id("prsn/jenkins:master-${env.BRANCH_NAME}")

    stage('Prep') {
      currentBuild.displayName="Prep"
      checkout scm
    }

    stage('Build') {
      currentBuild.displayName="Build"

      jenkinsImage.build()

      jenkinsImage.push()
    }
    
    stage('Test') {
      currentBuild.displayName="Test"

      jenkinsImage.inside {
        sh 'pwd'
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



   