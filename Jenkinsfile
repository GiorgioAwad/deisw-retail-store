pipeline {
  agent any

  tools {
    maven 'MAVEN_3_9_16'
    jdk 'JDK_26'
  }

  environment {
    REGISTRY_USER = "giorgioawad"
    STUDENT_CODE = "U202324041"

    IMAGE_NAME = "retail-store-${STUDENT_CODE}"
    TAG = "${env.BUILD_NUMBER}"

    FULL_IMAGE_TAG = "${REGISTRY_USER}/${IMAGE_NAME}:${TAG}"
    FULL_IMAGE_LATEST = "${REGISTRY_USER}/${IMAGE_NAME}:latest"
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
        withMaven(maven: 'MAVEN_3_9_16') {
          sh 'mvn clean compile'
        }
      }
    }

    stage('Validate Checkstyle') {
      steps {
        withMaven(maven: 'MAVEN_3_9_16') {
          sh 'mvn checkstyle:check'
        }
      }
    }

    stage('Validate Unit Tests') {
      steps {
        withMaven(maven: 'MAVEN_3_9_16') {
          sh 'mvn test'
        }
      }
    }

    stage('Validate Test Coverage') {
      steps {
        withMaven(maven: 'MAVEN_3_9_16') {
          sh 'mvn clean verify jacoco:report'
          sh 'mvn jacoco:check'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('MiSonarServer') {
          sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=retail-store'
        }

        script {
          timeout(time: 10, unit: 'MINUTES') {
            def qg = waitForQualityGate()

            if (qg.status != 'OK') {
              error "El pipeline se ha detenido porque el código no superó el Quality Gate de SonarQube. Estado: ${qg.status}"
            }
          }
        }
      }
    }

    stage('Build and Push Docker Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'DOCKER_HUB_CREDENTIALS',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          script {
            echo "Iniciando sesión en Docker Hub..."
            sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"

            echo "Construyendo y publicando imagen AMD64..."
            sh """
              docker buildx build \
                --platform linux/amd64 \
                -t ${FULL_IMAGE_TAG} \
                -t ${FULL_IMAGE_LATEST} \
                --push .
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline ejecutado correctamente."
      echo "Imagen publicada: ${FULL_IMAGE_TAG}"
      echo "Imagen latest publicada: ${FULL_IMAGE_LATEST}"
    }

    failure {
      echo "El pipeline falló. Revisar logs de Jenkins."
    }
  }
}
