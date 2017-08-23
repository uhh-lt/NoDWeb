# NoDWeb

## Setup
- Configure database settings in application.conf
- Install sbt
- Compile app `sbt dist`
- Extract result `unzip target/universal/nodweb-1.0.2.zip`
- Run server `target/universal/nodweb-1.0.2/bin/nodweb -DConfig.file=target/universal/nodweb-1.0.2/conf/application.conf`
