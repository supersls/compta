#!/bin/bash

echo "🚀 Démarrage de l'application Compta EI..."

# Vérifier que Docker est lancé
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker n'est pas démarré. Veuillez démarrer Docker Desktop."
  exit 1
fi

# Démarrer les conteneurs
echo "📦 Démarrage de PostgreSQL, Backend et pgAdmin..."
docker-compose up -d

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 5

# Vérifier que le backend est prêt
echo "⏳ Vérification du backend..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
  if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Backend prêt!"
    break
  fi
  attempt=$((attempt + 1))
  sleep 1
done

if [ $attempt -eq $max_attempts ]; then
  echo "❌ Le backend n'a pas démarré. Vérifiez les logs avec: docker-compose logs backend"
  exit 1
fi

# Afficher les informations
echo ""
echo "✅ Infrastructure démarrée avec succès!"
echo ""
echo "📊 Services disponibles:"
echo "  - Backend API: http://localhost:3000"
echo "  - Health check: http://localhost:3000/health"
echo "  - pgAdmin: http://localhost:5050 (admin@compta.fr / admin123)"
echo "  - PostgreSQL: localhost:5432 (postgres / postgres)"
echo ""
echo "🎨 Lancement de l'application Flutter..."
echo ""

# Lancer Flutter
cd front
flutter pub get
flutter run -d chrome
