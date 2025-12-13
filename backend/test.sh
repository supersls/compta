#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Base URL
BASE_URL="http://localhost:3000/api"

# Test function
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local expected_status=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}[Test $TOTAL_TESTS]${NC} $method $endpoint - $description"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Show response body if it's not too large
        if [ ${#body} -lt 500 ]; then
            echo -e "${YELLOW}Response:${NC} $body"
        else
            echo -e "${YELLOW}Response:${NC} $(echo "$body" | head -c 200)..."
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (Expected HTTP $expected_status, got HTTP $http_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}Response:${NC} $body"
    fi
    
    echo ""
}

echo "=========================================="
echo "    COMPTA EI - API INTEGRATION TESTS"
echo "=========================================="
echo ""

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
for i in {1..30}; do
    if curl -s "$BASE_URL/api/health" > /dev/null 2>&1; then
        echo -e "${GREEN}Backend is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Backend not responding after 30 seconds${NC}"
        exit 1
    fi
    sleep 1
done

echo ""
echo -e "${BLUE}========== HEALTH CHECK ==========${NC}"
test_endpoint "GET" "/health" "Health check" "" "200"

echo -e "${BLUE}========== FACTURES ENDPOINTS ==========${NC}"
test_endpoint "GET" "/factures" "Get all invoices" "" "200"
test_endpoint "GET" "/factures/stats/overview" "Get invoice statistics" "" "200"
test_endpoint "GET" "/factures/type/vente" "Get sales invoices" "" "200"
test_endpoint "GET" "/factures/type/achat" "Get purchase invoices" "" "200"
test_endpoint "GET" "/factures/statut/payee" "Get paid invoices" "" "200"
test_endpoint "GET" "/factures/statut/en_attente" "Get pending invoices" "" "200"
test_endpoint "GET" "/factures/filter/retard" "Get overdue invoices" "" "200"

echo -e "${BLUE}========== TVA ENDPOINTS ==========${NC}"
test_endpoint "GET" "/tva/declarations" "Get all TVA declarations" "" "200"

# Get current date for TVA calculation
DEBUT=$(date -d "2025-01-01" '+%Y-%m-%d' 2>/dev/null || date -v-1y '+%Y-%m-%d')
FIN=$(date '+%Y-%m-%d')

test_endpoint "GET" "/tva/calcul/$DEBUT/$FIN" "Calculate TVA for period" "" "200"

echo -e "${BLUE}========== BANQUE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/banque/comptes" "Get all bank accounts" "" "200"
test_endpoint "GET" "/banque/transactions" "Get all transactions" "" "200"
test_endpoint "GET" "/banque/statistiques" "Get bank statistics" "" "200"

# Get first account if exists
FIRST_ACCOUNT=$(curl -s "$BASE_URL/banque/comptes" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
if [ ! -z "$FIRST_ACCOUNT" ]; then
    test_endpoint "GET" "/banque/comptes/$FIRST_ACCOUNT/statistiques" "Get account statistics" "" "200"
    test_endpoint "GET" "/banque/comptes/$FIRST_ACCOUNT/transactions" "Get account transactions" "" "200"
fi

echo -e "${BLUE}========== IMMOBILISATIONS ENDPOINTS ==========${NC}"
test_endpoint "GET" "/immobilisations" "Get all fixed assets" "" "200"
test_endpoint "GET" "/immobilisations/statistiques" "Get immobilisations statistics" "" "200"

echo -e "${BLUE}========== DOCUMENTS COMPTABLES ENDPOINTS ==========${NC}"
test_endpoint "GET" "/documents/journal?dateDebut=2025-01-01&dateFin=2025-12-31" "Get journal comptable" "" "200"
test_endpoint "GET" "/documents/grand-livre?dateDebut=2025-01-01&dateFin=2025-12-31" "Get grand livre" "" "200"
test_endpoint "GET" "/documents/bilan?date=2025-12-31" "Get balance sheet" "" "200"
test_endpoint "GET" "/documents/compte-resultat?dateDebut=2025-01-01&dateFin=2025-12-31" "Get income statement" "" "200"

echo -e "${BLUE}========== ENTREPRISE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/entreprise" "Get company info" "" "200"

echo -e "${BLUE}========== COMPTABILITE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/comptabilite/comptes" "Get accounting plan" "" "200"

echo ""
echo "=========================================="
echo "           TEST SUMMARY"
echo "=========================================="
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
