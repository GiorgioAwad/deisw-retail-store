pipeline {
  agent any

  environment {
    REGISTRY_USER = "giorgioawad"
    STUDENT_CODE = "u202324041"

    IMAGE_NAME = "retail-store-${STUDENT_CODE}"
    TAG = "${env.BUILD_NUMBER}"

    FULL_IMAGE_TAG = "${REGISTRY_USER}/${IMAGE_NAME}:${TAG}"
    FULL_IMAGE_LATEST = "${REGISTRY_USER}/${IMAGE_NAME}:latest"

    MAVEN_IMAGE = "maven:3.9.16-eclipse-temurin-26-alpine"
    JENKINS_CONTAINER = "jenkins-master"
  }

  stages {
    stage('Validate Environment') {
      steps {
        sh """
          docker run --rm ${MAVEN_IMAGE} java -version
          docker run --rm ${MAVEN_IMAGE} mvn -version
          docker --version
        """
      }
    }

    stage('Validate Workspace') {
      steps {
        sh """
          echo "Workspace actual:"
          pwd

          echo "Archivos encontrados:"
          ls -la

          echo "Validando pom.xml:"
          test -f pom.xml
        """
      }
    }

    stage('Compile Project') {
      steps {
        sh """
          docker run --rm \
            --volumes-from ${JENKINS_CONTAINER} \
            -v maven-repo:/root/.m2 \
            -w "$WORKSPACE" \
            ${MAVEN_IMAGE} \
            mvn clean compile
        """
      }
    }

    stage('Validate Checkstyle') {
      steps {
        sh """
          docker run --rm \
            --volumes-from ${JENKINS_CONTAINER} \
            -v maven-repo:/root/.m2 \
            -w "$WORKSPACE" \
            ${MAVEN_IMAGE} \
            mvn checkstyle:check
        """
      }
    }

    stage('Validate Unit Tests') {
      steps {
        sh """
          docker run --rm \
            --volumes-from ${JENKINS_CONTAINER} \
            -v maven-repo:/root/.m2 \
            -w "$WORKSPACE" \
            ${MAVEN_IMAGE} \
            mvn test
        """
      }
    }

    stage('Validate Test Coverage') {
      steps {
        sh """
          docker run --rm \
            --volumes-from ${JENKINS_CONTAINER} \
            -v maven-repo:/root/.m2 \
            -w "$WORKSPACE" \
            ${MAVEN_IMAGE} \
            mvn clean verify jacoco:report

          docker run --rm \
            --volumes-from ${JENKINS_CONTAINER} \
            -v maven-repo:/root/.m2 \
            -w "$WORKSPACE" \
            ${MAVEN_IMAGE} \
            mvn jacoco:check
        """
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('MiSonarServer') {
          sh """
            docker run --rm \
              --volumes-from ${JENKINS_CONTAINER} \
              -v maven-repo:/root/.m2 \
              -w "$WORKSPACE" \
              -e SONAR_HOST_URL="$SONAR_HOST_URL" \
              -e SONAR_AUTH_TOKEN="$SONAR_AUTH_TOKEN" \
              ${MAVEN_IMAGE} \
              mvn clean verify sonar:sonar \
              -Dsonar.projectKey=retail-store-${STUDENT_CODE} \
              -Dsonar.host.url="$SONAR_HOST_URL" \
              -Dsonar.login="$SONAR_AUTH_TOKEN"
          """
        }

        script {
          timeout(time: 10, unit: 'MINUTES') {
            def qg = waitForQualityGate()

            if (qg.status != 'OK') {
              error "El pipeline se detuvo porque no superó el Quality Gate de SonarQube. Estado: ${qg.status}"
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
            sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"

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
