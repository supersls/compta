#!/bin/bash

echo "🚀 Démarrage de l'application Compta EI..."

# Vérifier que Docker est lancé
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker n'est pas démarré. Veuillez démarrer Docker Desktop."
  exit 1
fi

# Vérifier si rebuild est demandé
REBUILD=false
if [ "$1" == "--rebuild" ] || [ "$1" == "-r" ]; then
  REBUILD=true
  echo "🔨 Mode rebuild activé - Reconstruction du backend..."
fi

# Arrêter les conteneurs existants
if $REBUILD; then
  echo "⏹️  Arrêt des conteneurs..."
  docker-compose down
  
  # Supprimer l'image backend
  echo "🗑️  Suppression de l'image backend..."
  docker rmi compta-backend 2>/dev/null || echo "   Image backend non trouvée, skip."
  
  # Reconstruire l'image backend sans cache
  echo "🏗️  Reconstruction de l'image backend (sans cache)..."
  docker-compose build --no-cache backend
  
  # Démarrer tous les conteneurs
  echo "📦 Démarrage de PostgreSQL, Backend et pgAdmin..."
  docker-compose up -d
else
  # Démarrer les conteneurs normalement
  echo "📦 Démarrage de PostgreSQL, Backend et pgAdmin..."
  docker-compose up -d
fi

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 5

# Vérifier que le backend est prêt
echo "⏳ Vérification du backend..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
  if curl -s http://localhost:3000/api/health > /dev/null; then
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
if $REBUILD; then
  echo "✅ Reconstruction et démarrage terminés avec succès!"
else
  echo "✅ Infrastructure démarrée avec succès!"
fi
echo ""
echo "📊 Services disponibles:"
echo "  - Backend API: http://localhost:3000"
echo "  - Health check: http://localhost:3000/api/health"
echo "  - pgAdmin: http://localhost:5050 (admin@compta.fr / admin123)"
echo "  - PostgreSQL: localhost:5432 (postgres / postgres)"
echo ""
echo "🎨 Lancement de l'application Flutter..."
echo ""
echo "💡 Astuce: Utilisez './start.sh --rebuild' pour forcer la reconstruction du backend"
echo ""

# Lancer Flutter
cd front
flutter pub get
flutter run -d chrome
