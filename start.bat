@echo off
echo 🚀 Démarrage de l'application Compta EI...

REM Vérifier que Docker est lancé
docker info >nul 2>&1
if errorlevel 1 (
  echo ❌ Docker n'est pas démarré. Veuillez démarrer Docker Desktop.
  exit /b 1
)

REM Démarrer les conteneurs
echo 📦 Démarrage de PostgreSQL, Backend et pgAdmin...
docker-compose up -d

REM Attendre que PostgreSQL soit prêt
echo ⏳ Attente de PostgreSQL...
timeout /t 5 /nobreak >nul

REM Vérifier que le backend est prêt
echo ⏳ Vérification du backend...
set max_attempts=30
set attempt=0

:check_backend
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% equ 0 (
  echo ✅ Backend prêt!
  goto backend_ready
)

set /a attempt+=1
if %attempt% geq %max_attempts% (
  echo ❌ Le backend n'a pas démarré. Vérifiez les logs avec: docker-compose logs backend
  exit /b 1
)

timeout /t 1 /nobreak >nul
goto check_backend

:backend_ready
echo.
echo ✅ Infrastructure démarrée avec succès!
echo.
echo 📊 Services disponibles:
echo   - Backend API: http://localhost:3000
echo   - Health check: http://localhost:3000/health
echo   - pgAdmin: http://localhost:5050 (admin@compta.fr / admin123)
echo   - PostgreSQL: localhost:5432 (postgres / postgres)
echo.
echo 🎨 Lancement de l'application Flutter...
echo.

REM Lancer Flutter
cd front
flutter pub get
flutter run -d chrome
