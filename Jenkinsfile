#!/usr/bin/env groovy

node('centos7') {

  docker.withRegistry('https://quay.io', 'quay-bryan-test') {

    stage('Prep') {
      currentBuild.displayName="Prep"
      checkout scm
    }

    stage('Build') {
      currentBuild.displayName="Build"

      def image = docker.build("quay.io/prsn/jenkins:master-${env.BRANCH_NAME}", '.')
    }

    stage('Test') {
      currentBuild.displayName="Test"

      image.inside() {
        sh 'pwd'
      }
    }

    stage('Accept') {
      currentBuild.displayName="Accept"
      input 'Image Acceptable?'
    }

    stage('Publish') {
      currentBuild.displayName="Publish"
      image.push();
    }
  }
}



   