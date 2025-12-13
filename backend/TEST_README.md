# API Integration Tests

This directory contains comprehensive integration tests for all Compta EI backend API endpoints.

## Test Files

### 1. `test.sh` - Bash Test Suite
Shell script that tests all API endpoints using `curl`. This is useful for quick validation and CI/CD pipelines.

**Features:**
- Color-coded output (red/green for pass/fail)
- Tests all endpoints with real database data
- HTTP status code validation
- Response body preview
- Test summary with pass/fail counters

**Usage:**
```bash
# Make executable
chmod +x backend/test.sh

# Run tests
./backend/test.sh
```

### 2. `test.js` - Node.js Test Suite
JavaScript-based test suite using Node.js built-in `http` module. More detailed with better JSON parsing.

**Features:**
- Pure Node.js (no external dependencies)
- JSON response parsing and validation
- Waits for backend readiness (30-second timeout)
- Comprehensive error handling
- Detailed test output with response previews

**Usage:**
```bash
cd backend
node test.js
```

## Test Coverage

Both test suites cover the following endpoints:

### Health Check
- `GET /api/health` - Backend health status

### Factures (Invoices)
- `GET /api/factures` - List all invoices
- `GET /api/factures/stats/overview` - Invoice statistics
- `GET /api/factures/type/vente` - Sales invoices
- `GET /api/factures/type/achat` - Purchase invoices
- `GET /api/factures/statut/payee` - Paid invoices
- `GET /api/factures/statut/en_attente` - Pending invoices
- `GET /api/factures/filter/retard` - Overdue invoices

### TVA (VAT)
- `GET /api/tva/declarations` - TVA declarations
- `GET /api/tva/calcul/{debut}/{fin}` - TVA calculation for period

### Banque (Bank)
- `GET /api/banque/comptes` - Bank accounts
- `GET /api/banque/transactions` - Transactions
- `GET /api/banque/statistiques` - Bank statistics
- `GET /api/banque/comptes/{id}/statistiques` - Account statistics
- `GET /api/banque/comptes/{id}/transactions` - Account transactions

### Immobilisations (Fixed Assets)
- `GET /api/immobilisations` - Fixed assets
- `GET /api/immobilisations/statistiques` - Fixed assets statistics

### Documents Comptables (Accounting Documents)
- `GET /api/documents/journal` - Journal comptable
- `GET /api/documents/grand-livre` - Grand livre
- `GET /api/documents/bilan` - Balance sheet
- `GET /api/documents/compte-resultat` - Income statement

### Entreprise (Company)
- `GET /api/entreprise` - Company information

### Comptabilité (Accounting)
- `GET /api/comptabilite/comptes` - Accounting plan

## Prerequisites

### Running Tests

1. **Backend running:**
   ```bash
   cd /path/to/compta
   docker-compose up -d
   ```

2. **Database seeded:**
   The tests use real data from the PostgreSQL database. Ensure the database has been initialized with `init.sql` and seed data.

3. **Backend responding:**
   The tests automatically wait up to 30 seconds for the backend to respond.

## Running Tests from CI/CD

### GitHub Actions Example
```yaml
- name: Run API Tests
  run: |
    chmod +x backend/test.sh
    ./backend/test.sh
```

### Docker Example
```bash
docker-compose exec -T backend node test.js
```

## Test Output

### Bash Test Output Example
```
==========================================
    COMPTA EI - API INTEGRATION TESTS
==========================================

Waiting for backend to be ready...
Backend is ready!

========== HEALTH CHECK ==========
[Test 1] GET /health - Health check
✓ PASS (HTTP 200)
Response: {"status":"OK","timestamp":"2025-12-13T10:30:00.000Z"}

========== FACTURES ENDPOINTS ==========
[Test 2] GET /factures - Get all invoices
✓ PASS (HTTP 200)
Response: [{"id":1,"numero":"FAC-2025-001"...
```

### Node.js Test Output Example
```
==================================================
    COMPTA EI - API INTEGRATION TESTS
==================================================

Waiting for backend to be ready...
Backend is ready!

========== HEALTH CHECK ==========
[Test 1] GET /api/health - Health check
✓ PASS (HTTP 200)
Response: {"status":"OK","timestamp":"2025-12-13T10:30:00.000Z"}
```

## Test Results

- **PASS** (✓): Endpoint responded with expected HTTP status code
- **FAIL** (✗): Endpoint responded with different status code or error
- **ERROR**: Network error or connection refused

## Troubleshooting

### "Backend not responding"
- Ensure Docker containers are running: `docker-compose ps`
- Check backend logs: `docker-compose logs backend`
- Verify database is initialized: `docker-compose logs postgres`

### "Connection refused"
- Backend may not have started yet
- Check if port 3000 is in use: `lsof -i :3000` (Unix) or `netstat -ano | findstr :3000` (Windows)

### Individual endpoint failures
- Check backend logs for specific errors
- Verify database has seed data
- Ensure required tables exist in PostgreSQL

## Adding New Tests

To add tests for new endpoints:

### In `test.sh`:
```bash
test_endpoint "GET" "/your/new/endpoint" "Description of test" "" "200"
```

### In `test.js`:
```javascript
await testEndpoint('GET', '/api/your/new/endpoint', 'Description of test');
```

## Performance Notes

- Tests run sequentially to avoid database locks
- Average test suite execution: ~5-10 seconds
- Each endpoint test includes database query execution
- Tests validate actual data from the database, not mock data

## Notes

- All tests use real data from the PostgreSQL database
- No data is modified (all tests use GET requests)
- Tests validate HTTP status codes and response structure
- Response bodies are parsed and previewed (limited to 300 characters)
