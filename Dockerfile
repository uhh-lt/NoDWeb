FROM openjdk:8

RUN apt-get update && apt-get upgrade -y

ENV SCALA_VERSION 2.12.2
ENV SBT_VERSION 0.13.15

RUN \
  curl -fsL http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /root/ && \
  echo >> /root/.bashrc && \
  echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc

RUN \
  curl -L -o sbt-$SBT_VERSION.deb http://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  sbt sbtVersion

COPY . /app
WORKDIR /app
RUN sbt dist
RUN \
  mv target/universal/nodweb-1.0.2.zip /tmp \
  && rm -rf /app/* && \
  unzip /tmp/nodweb-1.0.2.zip -d /app

CMD /app/nodweb-1.0.2/bin/nodweb -DConfig.file=/app/nodweb-1.0.2/conf/application.conf