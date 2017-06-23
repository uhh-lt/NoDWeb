name := "NoDWeb"

version := "1.0.2"

scalaVersion := "2.11.6"

scalacOptions += "-feature"

libraryDependencies ++= Seq(
  jdbc,
  "com.typesafe.play" %% "anorm" % "2.4.0",
  "mysql" % "mysql-connector-java" % "5.1.35",
  "net.sf.jung" % "jung-api" % "2.0.1",
  "net.sf.jung" % "jung-graph-impl" % "2.0.1",
  "net.sf.jung" % "jung-algorithms" % "2.0.1",
  "com.thoughtworks.xstream" % "xstream" % "1.4.4",
  "org.apache.lucene" % "lucene-snowball" % "3.0.3",
  "commons-io" % "commons-io" % "2.4",
  "edu.stanford.nlp" % "stanford-corenlp" % "3.5.2"
)

lazy val root = (project in file(".")).enablePlugins(PlayScala)

