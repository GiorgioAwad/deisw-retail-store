# Build stage: Maven + Temurin 26 JDK
FROM maven:3.9.16-eclipse-temurin-26-alpine AS build

WORKDIR /workspace

# Copiar pom.xml primero para aprovechar cache de dependencias
COPY pom.xml .

RUN mvn -B -f pom.xml -DskipTests dependency:go-offline

# Copiar el resto del proyecto
COPY . .

# Construir el proyecto sin ejecutar tests
RUN mvn -B -DskipTests package


# Runtime stage: Eclipse Temurin 26 JRE Alpine
FROM eclipse-temurin:26-jre-alpine

WORKDIR /app

# Copiar el JAR generado
COPY --from=build /workspace/target/*.jar app.jar

# Variables por defecto
ENV SPRING_PROFILES_ACTIVE=dev
ENV PORT=8091
ENV JAVA_OPTS=""

EXPOSE 8091

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -Dserver.port=${PORT} -jar /app/app.jar"]
