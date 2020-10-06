FROM golang:1.15 AS build_base

# Configure Git to use SSH
RUN git config --global url."git@bitbucket.org:".insteadOf "https://bitbucket.org/"
RUN go env -w GOPRIVATE=bitbucket.org/carrierlabs/*

RUN apt-get update && apt-get install -y ca-certificates git-core ssh
COPY ./.ssh/id_rsa  /root/.ssh/id_rsa
RUN chmod 700 /root/.ssh/id_rsa

# make sure your domain is accepted
# RUN echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Set the Current Working Directory inside the container
WORKDIR /.

# We want to populate the module cache based on the go.{mod,sum} files.
COPY . . 
RUN go mod download

# Build Server
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o server

# Start fresh from a smaller image
FROM alpine:latest
RUN apk add ca-certificates

COPY --from=build_base /server .

# This container exposes port 8080 to the outside world
EXPOSE 8080

# Run the binary program produced by `go install`
CMD ["/server"]