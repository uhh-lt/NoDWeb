# NoDWeb

Before the NoDWeb project can be used it needs some data created by the [NoDCore project](https://github.com/uhh-lt/NoDCore)

## Setup
- Configure database settings in application.conf
- Install sbt
- Compile app `sbt dist`
- Extract result `cd target/universal && unzip nodweb-1.0.2.zip`
- Run server `target/universal/nodweb-1.0.2/bin/nodweb -DConfig.file=target/universal/nodweb-1.0.2/conf/application.conf`
- Open `localhost:9000`

A full setup for NoDWeb and NoDCore is available in the [NoDCore](https://github.com/uhh-lt/NoDCore) repo