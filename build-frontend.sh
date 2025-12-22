#!/bin/bash
# Build Flutter Web Locally for Deployment
# Run this script on your local machine before pushing to GitHub

set -e

echo "=========================================="
echo "Building Flutter Web for Production"
echo "=========================================="
echo ""

# Navigate to front directory
cd "$(dirname "$0")/front"

# Get EC2 IP (you need to update this after launching EC2)
read -p "Enter your EC2 Public IP (or press Enter for localhost): " EC2_IP
EC2_IP=${EC2_IP:-localhost}

# Determine the API URL based on input
if [ "$EC2_IP" = "localhost" ]; then
    API_URL="http://localhost:3000/api"
else
    API_URL="http://${EC2_IP}:3000/api"
fi

echo "📝 Updating API config for: $API_URL"

# Update API config
cat > lib/config/api_config.dart <<DART
class ApiConfig {
  // Change this to your EC2 IP or domain for production
  // Example: 'http://3.123.45.67:3000/api' or 'https://api.yourdomain.com/api'
  static const String baseUrl = '${API_URL}';
  
  // Endpoints
  static const String factures = '\$baseUrl/factures';
  static const String tva = '\$baseUrl/tva';
  static const String banque = '\$baseUrl/banque';
  static const String immobilisations = '\$baseUrl/immobilisations';
  static const String comptabilite = '\$baseUrl/comptabilite';
  static const String entreprise = '\$baseUrl/entreprise';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
DART

echo "🏗️  Building Flutter web..."
flutter build web --release

echo "📦 Preparing dist folder..."
# Remove old dist folder
rm -rf dist

# Copy build/web to dist
cp -r build/web dist

echo ""
echo "=========================================="
echo "✅ Build Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Commit and push to GitHub:"
echo "   git add front/dist front/lib/config/api_config.dart"
echo "   git commit -m 'Build frontend for deployment'"
echo "   git push"
echo ""
echo "2. Deploy to EC2 (the user data script will copy from front/dist)"
echo ""
echo "Or manually deploy:"
echo "   scp -i your-key.pem -r front/dist/* ec2-user@$EC2_IP:/var/www/compta/"
echo ""
