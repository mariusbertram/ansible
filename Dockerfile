FROM  alpine:latest as build
ENV PYTHON_VERSION=3.10.7

RUN apk add --no-cache libxslt libxml2 libffi-dev build-base curl zlib  openssl-dev openssl-libs-static zlib-dev
WORKDIR /tmp
RUN curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && mv Python-${PYTHON_VERSION}.tgz python.tgz
RUN tar -xvzf /tmp/python.tgz

WORKDIR /tmp/Python-${PYTHON_VERSION}

RUN ./configure \
    --prefix=/opt/python/${PYTHON_VERSION} \
    --enable-ipv6 \
    LDFLAGS=-Wl,-rpath=/opt/python/${PYTHON_VERSION}/lib,--disable-new-dtags

RUN make && make install

ENV PATH="/opt/python/${PYTHON_VERSION}/bin:$PATH"

COPY requirements.txt .

RUN pip3 install -r requirements.txt

FROM alpine:latest as production
ENV PYTHON_VERSION=3.10.7
ENV KUBECTL_VERSION=v1.23.0
ENV HELM_VERSION=v3.9.4
ENV OC_VERSION=4.10.17
RUN apk add --no-cache git libffi libxml2 libxslt curl

COPY --from=build /opt/python /opt/python

WORKDIR /usr/local/bin

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64//kubectl   && chmod +x kubectl
RUN curl https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz  | tar -xz linux-amd64/helm && mv linux-amd64/helm ./helm && rmdir linux-amd64 && chmod +x helm
RUN curl https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz | tar -xz oc && chmod +x oc


RUN ln -s -f /opt/python/${PYTHON_VERSION}/bin/python3 /opt/python/${PYTHON_VERSION}/bin/python && \
ln -s -f /opt/python/${PYTHON_VERSION}/bin/pip3 /opt/python/${PYTHON_VERSION}/bin/pip

WORKDIR /data
COPY requirements-galaxy.yaml /data
RUN echo "installing ansible collection" && ansible-galaxy collection install -r requirements-galaxy.yaml && rm requirements-galaxy.yaml

ENV PATH="/opt/python/${PYTHON_VERSION}/bin:$PATH"


CMD [ "sh" ]
