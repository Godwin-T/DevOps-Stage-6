FROM golang:1.21 AS builder
WORKDIR /src

# Download go modules first to leverage Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-api

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /src/auth-api /app/auth-api

EXPOSE 8081
ENTRYPOINT ["/app/auth-api"]
