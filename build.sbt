val scala3Version = "3.7.4"

lazy val root = (project in file("."))

lazy val core = (project in file("core"))
  .settings(
    name := "core",
    version := "0.1.0-SNAPSHOT",
    scalaVersion := scala3Version,
  )

lazy val frontend = project
  .in(file("frontend"))
  .dependsOn(core)
  .settings(
    name := "frontend",
    version := "0.1.0-SNAPSHOT",
    scalaVersion := scala3Version,
    libraryDependencies += "com.lihaoyi" %% "fastparse" % "3.1.1",
    libraryDependencies += "org.scalactic" %% "scalactic" % "3.2.19",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % "test"
  )
