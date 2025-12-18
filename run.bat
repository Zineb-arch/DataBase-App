@echo off
REM Simple helper: compile and run HostLinkApp with the PostgreSQL JDBC jar in lib\
SET JAR=lib\postgresql-42.x.x.jar
IF NOT EXIST "%JAR%" (
  echo PostgreSQL JDBC jar not found: %JAR%
  echo Download from https://jdbc.postgresql.org/download/ and place the jar under lib\
  pause
  exit /b 1
)

SET CLASSPATH=.;%JAR%
echo Compiling Java sources...
javac -cp "%CLASSPATH%" *.java
IF ERRORLEVEL 1 (
  echo Build failed.
  pause
  exit /b 1
)

echo Running HostLinkApp...
java -cp "%CLASSPATH%" HostLinkApp
pause