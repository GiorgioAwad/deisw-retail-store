pipeline {
  agent {
    docker {
      image 'maven:3.9.16-eclipse-temurin-26-alpine'
      args '-v $HOME/.m2:/root/.m2 -v /var/run/docker.sock:/var/run/docker.sock'
      reuseNode true
    }
  }

  environment {
    DOCKERHUB_USER = 'giorgioawad'
    STUDENT_CODE = 'U202324041'
    IMAGE_NAME = "retail-store-${STUDENT_CODE}"
    IMAGE_TAG = 'v1'
    FULL_IMAGE_NAME = "${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
  }

  stages {
    stage('Validate Environment') {
      steps {
        sh 'java -version'
        sh 'mvn -version'
        sh 'docker --version'
      }
    }

    stage('Compile Project') {
      steps {
        sh 'mvn clean compile'
      }
    }

    stage('Validate Checkstyle') {
      steps {
        sh 'mvn checkstyle:check'
      }
    }

    stage('Validate Unit Tests') {
      steps {
        sh 'mvn test'
      }
    }

    stage('Validate Test Coverage') {
      steps {
        sh 'mvn clean verify jacoco:report'
        sh 'mvn jacoco:check'
      }
    }

    /*
    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonarLocal') {
          sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=retail-store'
        }
      }
    }
    */

    stage('Package Project') {
      steps {
        sh 'mvn package -DskipTests'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $FULL_IMAGE_NAME .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-credentials',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          sh 'docker push $FULL_IMAGE_NAME'
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
    }

    success {
      echo "Pipeline ejecutado correctamente."
      echo "Imagen publicada: ${FULL_IMAGE_NAME}"
    }

    failure {
      echo "El pipeline falló. Revisar logs de Jenkins."
    }
  }
}
