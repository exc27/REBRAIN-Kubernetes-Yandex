# Build environment
# -----------------
FROM golang:1.15-alpine as build-env
WORKDIR /helm-secrets
RUN apk update && apk add --no-cache gcc musl-dev git
COPY . .
RUN go build -ldflags '-w -s' -a -o ./bin/helm-secrets ./cmd/helm-secrets

# Deployment environment
# ----------------------
FROM alpine
RUN apk update && apk add --no-cache bash wget
RUN mkdir -p ~/.postgresql && wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" -O ~/.postgresql/root.crt && chmod 0600 ~/.postgresql/root.crt
COPY --from=build-env /helm-secrets/bin/helm-secrets /opt/
COPY migrations /opt/migrations
CMD ["/opt/helm-secrets"]
