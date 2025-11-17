# Multi-stage Dockerfile for the ChatApp Spring Boot backend
# Stage 1: build with Maven (uses the Maven wrapper if present)
FROM maven:3.8.8-openjdk-21 AS build
WORKDIR /workspace/app

# Copy only the files needed for dependency resolution first to leverage Docker cache
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw || true

# Copy source and build
COPY src ./src
# Use the wrapper if present, otherwise fall back to mvn from the base image
RUN if [ -x "./mvnw" ]; then ./mvnw -B -DskipTests package; else mvn -B -DskipTests package; fi

# Stage 2: runtime image
FROM eclipse-temurin:21-jre-jammy
ARG JAR_FILE=/workspace/app/target/*.jar

# Copy the executable jar from the build stage
COPY --from=build ${JAR_FILE} /app/app.jar

# Recommended environment variables (tweak as needed)
ENV JAVA_OPTS=""
ENV SPRING_OUTPUT_ANSI_ENABLED=ALWAYS
ENV SERVER_PORT=8080

EXPOSE 8080

# Run with sensible defaults; allow overriding ENTRYPOINT/CMD with different JAVA_OPTS
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
