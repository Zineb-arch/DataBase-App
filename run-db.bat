@echo off
REM Robust run-db helper: detects docker compose command, starts DB, and waits for readiness with diagnostics
setlocal enabledelayedexpansion
SET SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

IF NOT EXIST "docker-compose.yml" (
  echo docker-compose.yml not found in %SCRIPT_DIR%
  exit /b 1
)

REM Detect docker compose command
set DOCKER_COMPOSE_CMD=
where docker >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Docker CLI not found. Attempting to fall back to a local PostgreSQL installation (psql)...
  where psql >nul 2>&1
  if %ERRORLEVEL%==0 (
    echo Found psql in PATH — will attempt to initialize the DB locally.
    REM Ask user whether to proceed
    set /p CHOICE="Proceed to initialize DB with local psql (will create DB hostlinkDB and run hostlinkDB.sql)? [Y/N]: "
    if /i "%CHOICE%"=="Y" (
      REM Use PGPASSWORD to non-interactively pass the password; user-provided default is 507729
      set PGPASSWORD=507729
      echo Creating database 'hostlinkDB' (if not exists)...
      psql -U postgres -c "SELECT 1" >nul 2>&1
      if %ERRORLEVEL% NEQ 0 (
        echo Failed to authenticate with psql as postgres. Ensure postgres user password is 507729 or set PGPASSWORD appropriately.
        exit /b 1
      )
      psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='hostlinkDB'" | findstr 1 >nul 2>&1
      if %ERRORLEVEL% NEQ 0 (
        psql -U postgres -c "CREATE DATABASE hostlinkDB" || (
          echo Failed to create database hostlinkDB; check postgres server status and credentials.
          exit /b 1
        )
        echo Database hostlinkDB created.
      ) else (
        echo Database hostlinkDB already exists.
      )
      if exist "%SCRIPT_DIR%hostlinkDB.sql" (
        echo Applying schema/data from hostlinkDB.sql...
        psql -U postgres -d hostlinkDB -f "%SCRIPT_DIR%hostlinkDB.sql" || (
          echo Failed to run hostlinkDB.sql; check file and database permissions.
          exit /b 1
        )
        echo Schema/data applied successfully.
        echo PostgreSQL local instance is ready.
        pause
        exit /b 0
      ) else (
        echo hostlinkDB.sql not found; nothing to apply. Ensure script exists in project root.
        pause
        exit /b 1
      )
    ) else (
      echo Aborting as requested. Install Docker Desktop or ensure psql is configured before retrying.
      exit /b 1
    )
  ) else (
    echo Docker CLI and local psql were not found. Please install Docker Desktop or PostgreSQL.
    exit /b 1
  )
)

REM prefer 'docker compose' if available
docker compose version >nul 2>&1
if %ERRORLEVEL%==0 (
  set DOCKER_COMPOSE_CMD=docker compose
) else (
  docker-compose version >nul 2>&1
  if %ERRORLEVEL%==0 (
    set DOCKER_COMPOSE_CMD=docker-compose
  )
)

if "%DOCKER_COMPOSE_CMD%"=="" (
  echo Docker Compose not found (tried 'docker compose' and 'docker-compose'). Install Docker Compose or upgrade Docker Desktop.
  exit /b 1
)

echo Using %DOCKER_COMPOSE_CMD% in %CD%

REM Verify hostlinkDB.sql exists and is readable
if not exist "%SCRIPT_DIR%hostlinkDB.sql" (
  echo Warning: hostlinkDB.sql not found in project root; container init may fail if the file is required.
) else (
  echo Found hostlinkDB.sql at %SCRIPT_DIR%hostlinkDB.sql
)

REM Start the DB container
%DOCKER_COMPOSE_CMD% up -d db
if %ERRORLEVEL% NEQ 0 (
  echo Failed to start container. Showing docker ps -a and recent logs:
  docker ps -a
  docker logs hostlink-db --tail 200
  exit /b 1
)

echo Container start command issued. Waiting for PostgreSQL to become ready...
set /a count=0
:waitloop
REM Check if container exists and its status
for /f "tokens=*" %%i in ('docker ps --filter "name=hostlink-db" --format "{{.Status}}"') do set status=%%i
if "%status%"=="" (
  echo Container 'hostlink-db' not found in docker ps. Showing all containers:
  docker ps -a
  exit /b 1
)
echo Container status: %status%

REM Use pg_isready inside the container
docker exec hostlink-db pg_isready -U postgres -d hostlinkDB >nul 2>&1
if %ERRORLEVEL%==0 (
  echo PostgreSQL is ready.
  goto ready
)

set /a count+=1
if %count% GTR 60 (
  echo Timeout waiting for DB to be ready. Showing last 200 lines of logs:
  docker logs hostlink-db --tail 200
  echo Checking if port 5432 is in use locally:
  netstat -ano | findstr ":5432"
  exit /b 1
)

ping -n 2 127.0.0.1 >nul
goto waitloop

:ready

echo PostgreSQL container is healthy and accepting connections.

echo You can now compile and run the Java app (make sure JDBC jar is in lib/)
echo Example:
	echo javac -cp ".;lib\postgresql-42.x.x.jar" *.java
	echo java -cp ".;lib\postgresql-42.x.x.jar" HostLinkApp
pause