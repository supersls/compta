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

# Get first invoice ID if exists for testing
FIRST_INVOICE=$(curl -s "$BASE_URL/factures" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
if [ ! -z "$FIRST_INVOICE" ]; then
    test_endpoint "GET" "/factures/$FIRST_INVOICE" "Get invoice by ID" "" "200"
fi

# Test invoice search
test_endpoint "POST" "/factures/search" "Search invoices" '{"query": "Client"}' "200"

# Test generate invoice number
test_endpoint "POST" "/factures/generer-numero" "Generate invoice number" '{"type": "vente"}' "200"

# Test get invoices by period
test_endpoint "GET" "/factures/periode/2025-01-01/2025-12-31" "Get invoices by period" "" "200"

echo -e "${BLUE}========== TVA ENDPOINTS ==========${NC}"
test_endpoint "GET" "/tva/declarations" "Get all TVA declarations" "" "200"

# Get current date for TVA calculation
DEBUT=$(date -d "2025-01-01" '+%Y-%m-%d' 2>/dev/null || date -v-1y '+%Y-%m-%d')
FIN=$(date '+%Y-%m-%d')

test_endpoint "GET" "/tva/calcul/$DEBUT/$FIN" "Calculate TVA for period" "" "200"

# Test TVA statistics
test_endpoint "GET" "/tva/statistiques" "Get TVA statistics" "" "200"

# Test TVA detail by rate
test_endpoint "GET" "/tva/detail-taux/2025-01-01/2025-12-31" "Get TVA detail by rate" "" "200"

echo -e "${BLUE}========== BANQUE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/banque/comptes" "Get all bank accounts" "" "200"
test_endpoint "GET" "/banque/transactions" "Get all transactions" "" "200"
test_endpoint "GET" "/banque/statistiques" "Get bank statistics" "" "200"

# Create bank account
NEW_COMPTE=$(cat <<EOF
{
  "nom": "Compte Test",
  "banque": "Banque Test",
  "numero_compte": "12345678901",
  "iban": "FR7630006000011234567890189",
  "solde_initial": 10000,
  "solde_actuel": 10000,
  "date_ouverture": "2025-01-01",
  "actif": true
}
EOF
)
test_endpoint "POST" "/banque/comptes" "Create bank account" "$NEW_COMPTE" "201"

# Get first account if exists
FIRST_ACCOUNT=$(curl -s "$BASE_URL/banque/comptes" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
if [ ! -z "$FIRST_ACCOUNT" ]; then
    test_endpoint "GET" "/banque/comptes/$FIRST_ACCOUNT/statistiques" "Get account statistics" "" "200"
    test_endpoint "GET" "/banque/comptes/$FIRST_ACCOUNT/transactions" "Get account transactions" "" "200"
    test_endpoint "GET" "/banque/comptes/$FIRST_ACCOUNT/non-rapprochees" "Get unreconciled transactions" "" "200"
    
    # Update bank account
    UPDATED_COMPTE=$(cat <<EOF
{
  "id": $FIRST_ACCOUNT,
  "nom": "Compte Test Updated",
  "banque": "Banque Test",
  "numero_compte": "12345678901",
  "iban": "FR7630006000011234567890189",
  "solde_initial": 10000,
  "solde_actuel": 12000,
  "date_ouverture": "2025-01-01",
  "actif": true
}
EOF
)
    test_endpoint "PUT" "/banque/comptes/$FIRST_ACCOUNT" "Update bank account" "$UPDATED_COMPTE" "200"
    
    # Create transaction
    NEW_TRANSACTION=$(cat <<EOF
{
  "compte_bancaire_id": $FIRST_ACCOUNT,
  "date_transaction": "2025-12-13",
  "date_valeur": "2025-12-13",
  "libelle": "Test Transaction",
  "debit": 0,
  "credit": 1000,
  "solde": 11000,
  "rapproche": false
}
EOF
)
    test_endpoint "POST" "/banque/transactions" "Create transaction" "$NEW_TRANSACTION" "201"
    
    # Get created transaction
    FIRST_TRANSACTION=$(curl -s "$BASE_URL/banque/comptes/$FIRST_ACCOUNT/transactions" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
    
    if [ ! -z "$FIRST_TRANSACTION" ]; then
        # Update transaction
        UPDATED_TRANSACTION=$(cat <<EOF
{
  "id": $FIRST_TRANSACTION,
  "compte_bancaire_id": $FIRST_ACCOUNT,
  "date_transaction": "2025-12-13",
  "date_valeur": "2025-12-13",
  "libelle": "Test Transaction Updated",
  "debit": 0,
  "credit": 1500,
  "solde": 11500,
  "rapproche": false
}
EOF
)
        test_endpoint "PUT" "/banque/transactions/$FIRST_TRANSACTION" "Update transaction" "$UPDATED_TRANSACTION" "200"
        
        # Reconcile transaction
        test_endpoint "PATCH" "/banque/transactions/$FIRST_TRANSACTION/rapprocher" "Reconcile transaction" '{}' "200"
        
        # Delete transaction
        test_endpoint "DELETE" "/banque/transactions/$FIRST_TRANSACTION" "Delete transaction" "" "200"
    fi
fi

# Clean up - delete test account if created
TEST_ACCOUNT=$(curl -s "$BASE_URL/banque/comptes" | grep -o '"nom":"Compte Test' -A 100 | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
if [ ! -z "$TEST_ACCOUNT" ]; then
    test_endpoint "DELETE" "/banque/comptes/$TEST_ACCOUNT" "Delete test bank account" "" "200"
fi

echo -e "${BLUE}========== IMMOBILISATIONS ENDPOINTS ==========${NC}"
test_endpoint "GET" "/immobilisations" "Get all fixed assets" "" "200"
test_endpoint "GET" "/immobilisations/statistiques" "Get immobilisations statistics" "" "200"
test_endpoint "GET" "/immobilisations/par-categorie" "Get immobilisations by category" "" "200"
test_endpoint "GET" "/immobilisations/amortissements" "Get all depreciations" "" "200"

# Create immobilisation
NEW_IMMO=$(cat <<EOF
{
  "libelle": "Test Asset",
  "type": "Materiel informatique",
  "date_acquisition": "2025-01-01",
  "valeur_acquisition": 5000,
  "duree_amortissement": 5,
  "methode_amortissement": "lineaire",
  "taux_amortissement": 20,
  "valeur_residuelle": 0,
  "compte_immobilisation": "2183",
  "compte_amortissement": "28183",
  "en_service": true
}
EOF
)
test_endpoint "POST" "/immobilisations" "Create fixed asset" "$NEW_IMMO" "201"

# Get first immobilisation
FIRST_IMMO=$(curl -s "$BASE_URL/immobilisations" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

if [ ! -z "$FIRST_IMMO" ]; then
    # Update immobilisation
    UPDATED_IMMO=$(cat <<EOF
{
  "id": $FIRST_IMMO,
  "libelle": "Test Asset Updated",
  "type": "Materiel informatique",
  "date_acquisition": "2025-01-01",
  "valeur_acquisition": 6000,
  "duree_amortissement": 5,
  "methode_amortissement": "lineaire",
  "taux_amortissement": 20,
  "valeur_residuelle": 0,
  "compte_immobilisation": "2183",
  "compte_amortissement": "28183",
  "en_service": true
}
EOF
)
    test_endpoint "PUT" "/immobilisations/$FIRST_IMMO" "Update fixed asset" "$UPDATED_IMMO" "200"
    
    # Get amortissements for this immobilisation
    test_endpoint "GET" "/immobilisations/$FIRST_IMMO/amortissements" "Get asset depreciations" "" "200"
    
    # Calculate amortissement for a year
    test_endpoint "GET" "/immobilisations/$FIRST_IMMO/amortissement/2025" "Calculate depreciation for year" "" "200"
    
    # Delete immobilisation
    test_endpoint "DELETE" "/immobilisations/$FIRST_IMMO" "Delete fixed asset" "" "200"
fi

echo -e "${BLUE}========== DOCUMENTS COMPTABLES ENDPOINTS ==========${NC}"
test_endpoint "GET" "/documents/journal?dateDebut=2025-01-01&dateFin=2025-12-31" "Get journal comptable" "" "200"
test_endpoint "GET" "/documents/grand-livre?dateDebut=2025-01-01&dateFin=2025-12-31" "Get grand livre" "" "200"
test_endpoint "GET" "/documents/bilan?date=2025-12-31" "Get balance sheet" "" "200"
test_endpoint "GET" "/documents/compte-resultat?dateDebut=2025-01-01&dateFin=2025-12-31" "Get income statement" "" "200"
test_endpoint "GET" "/documents/balance?debut=2025-01-01&fin=2025-12-31" "Get balance des comptes" "" "200"

# Note: PDF/Excel export endpoints would require file download handling
# test_endpoint "GET" "/documents/export/pdf/journal?dateDebut=2025-01-01&dateFin=2025-12-31" "Export journal to PDF" "" "200"
# test_endpoint "GET" "/documents/export/excel/bilan?date=2025-12-31" "Export bilan to Excel" "" "200"

echo -e "${BLUE}========== ENTREPRISE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/entreprise" "Get company info" "" "200"

# Note: Add PUT/POST endpoints for entreprise if they exist in backend
# These would typically be used to update company information
# test_endpoint "PUT" "/entreprise/1" "Update company info" "$COMPANY_DATA" "200"

echo -e "${BLUE}========== COMPTABILITE ENDPOINTS ==========${NC}"
test_endpoint "GET" "/comptabilite/comptes" "Get accounting plan" "" "200"
test_endpoint "GET" "/comptabilite/plan-comptable" "Get plan comptable (alias)" "" "200"

# Note: Add endpoints for ecritures comptables if they exist
# test_endpoint "GET" "/comptabilite/ecritures" "Get accounting entries" "" "200"
# test_endpoint "POST" "/comptabilite/ecritures" "Create accounting entry" "$ECRITURE_DATA" "201"

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
