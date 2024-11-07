# Build stage
FROM golang:1.23 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files to the container
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go app and specify output binary name
RUN go build -o auth-service ./cmd/auth-service/main.go

# Runtime stage
FROM alpine:latest AS runtime

# Install necessary dependencies (if needed)
RUN apk add --no-cache libc6-compat

# Set the working directory inside the container
WORKDIR /root/

# Copy the db directory, including schema.sql
COPY --from=builder /app/db /root/db

# Copy the pre-built binary from the build stage
COPY --from=builder /app/auth-service .

# Copy the configuration directory (if needed for runtime)
COPY --from=builder /app/configs /root/configs

# Expose the port on which the application will run
EXPOSE 8080

# Command to run the executable
CMD ["./auth-service"]
