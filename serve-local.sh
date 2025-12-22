#!/bin/bash

# Serve Flutter frontend locally for testing

DIST_DIR="front/dist"
PORT=8080

if [ ! -d "$DIST_DIR" ]; then
    echo "❌ Error: $DIST_DIR not found"
    echo "Build frontend first with: cd front && flutter build web --release"
    exit 1
fi

echo "🚀 Starting local server..."
echo "📂 Serving: $DIST_DIR"
echo "🌐 URL: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop"
echo ""

cd $DIST_DIR
python -m http.server $PORT
