FROM alpine
ENV GOPATH /usr/local/go
ENV REPO $GOPATH/pixlet
ENV PATH "${PATH}:${GOPATH}/bin:${REPO}"

#install prereqs
RUN apk update && \
    apk upgrade -U && \
    apk add curl wget git make libc-dev gcc ca-certificates npm libwebp-dev libwebp-tools patchelf gcompat && \
    rm -rf /var/cache/*
RUN wget "https://go.dev/dl/go1.22.0.linux-armv6l.tar.gz" && tar -C /usr/local -xzf go*.linux-armv6l.tar.gz && rm -f go*.linux-armv6l.tar.gz

#Download Pixlet
RUN git clone https://github.com/tidbyt/pixlet.git $REPO 
WORKDIR $REPO

#Build Pixlet
RUN npm install && npm run build
RUN make build

#clean up build prereqs
RUN apk del -r curl wget git make gcc patchelf libc-dev 

#copy star files
RUN mkdir /star
COPY Star/* /star

EXPOSE 8080