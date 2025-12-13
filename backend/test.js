/**
 * API Integration Tests for Compta EI
 * Tests all backend endpoints with real data from database
 */

const http = require('http');
const BASE_URL = 'http://localhost:3000';

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

// Test statistics
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failedEndpoints = [];

/**
 * Make HTTP request
 */
function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          body: body,
        });
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

/**
 * Test an endpoint
 */
async function testEndpoint(
  method,
  path,
  description,
  expectedStatus = 200,
  data = null
) {
  totalTests++;
  const testNumber = totalTests;

  console.log(
    `${colors.blue}[Test ${testNumber}]${colors.reset} ${method} ${path} - ${description}`
  );

  try {
    const response = await makeRequest(method, path, data);

    if (response.status === expectedStatus) {
      console.log(`${colors.green}✓ PASS${colors.reset} (HTTP ${response.status})`);
      passedTests++;

      // Show response preview
      try {
        const json = JSON.parse(response.body);
        const responseStr = JSON.stringify(json);
        if (responseStr.length < 300) {
          console.log(`${colors.yellow}Response:${colors.reset} ${responseStr}`);
        } else {
          console.log(
            `${colors.yellow}Response:${colors.reset} ${responseStr.substring(0, 300)}...`
          );
        }
      } catch (e) {
        // Not JSON
        if (response.body.length < 300) {
          console.log(`${colors.yellow}Response:${colors.reset} ${response.body}`);
        }
      }
    } else {
      console.log(
        `${colors.red}✗ FAIL${colors.reset} (Expected HTTP ${expectedStatus}, got HTTP ${response.status})`
      );
      failedTests++;
      failedEndpoints.push(`${method} ${path}`);
      console.log(`${colors.red}Response:${colors.reset} ${response.body.substring(0, 500)}`);
    }
  } catch (error) {
    console.log(`${colors.red}✗ ERROR${colors.reset} ${error.message}`);
    failedTests++;
    failedEndpoints.push(`${method} ${path}`);
  }

  console.log('');
}

/**
 * Wait for backend to be ready
 */
async function waitForBackend(maxRetries = 30) {
  console.log(`${colors.yellow}Waiting for backend to be ready...${colors.reset}`);

  for (let i = 0; i < maxRetries; i++) {
    try {
      await makeRequest('GET', '/api/health');
      console.log(`${colors.green}Backend is ready!${colors.reset}\n`);
      return true;
    } catch (error) {
      if (i === maxRetries - 1) {
        console.log(
          `${colors.red}Backend not responding after ${maxRetries} seconds${colors.reset}`
        );
        process.exit(1);
      }
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('='.repeat(50));
  console.log('    COMPTA EI - API INTEGRATION TESTS');
  console.log('='.repeat(50));
  console.log('');

  // Wait for backend
  await waitForBackend();

  // ============ HEALTH CHECK ============
  console.log(`${colors.blue}========== HEALTH CHECK ==========${colors.reset}`);
  await testEndpoint('GET', '/api/health', 'Health check');

  // ============ FACTURES ============
  console.log(`${colors.blue}========== FACTURES ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/factures', 'Get all invoices');
  await testEndpoint('GET', '/api/factures/stats/overview', 'Get invoice statistics');
  await testEndpoint('GET', '/api/factures/type/vente', 'Get sales invoices');
  await testEndpoint('GET', '/api/factures/type/achat', 'Get purchase invoices');
  await testEndpoint('GET', '/api/factures/statut/payee', 'Get paid invoices');
  await testEndpoint('GET', '/api/factures/statut/en_attente', 'Get pending invoices');
  await testEndpoint('GET', '/api/factures/filter/retard', 'Get overdue invoices');

  // ============ TVA ============
  console.log(`${colors.blue}========== TVA ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/tva/declarations', 'Get all TVA declarations');

  const debut = '2025-01-01';
  const fin = '2025-12-31';
  await testEndpoint(
    'GET',
    `/api/tva/calcul/${debut}/${fin}`,
    'Calculate TVA for period'
  );

  // ============ BANQUE ============
  console.log(`${colors.blue}========== BANQUE ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/banque/comptes', 'Get all bank accounts');
  await testEndpoint('GET', '/api/banque/transactions', 'Get all transactions');
  await testEndpoint('GET', '/api/banque/statistiques', 'Get bank statistics');

  // Get first account for detailed tests
  try {
    const comptesRes = await makeRequest('GET', '/api/banque/comptes');
    const comptes = JSON.parse(comptesRes.body);
    if (Array.isArray(comptes) && comptes.length > 0) {
      const firstAccountId = comptes[0].id;
      await testEndpoint(
        'GET',
        `/api/banque/comptes/${firstAccountId}/statistiques`,
        'Get account statistics'
      );
      await testEndpoint(
        'GET',
        `/api/banque/comptes/${firstAccountId}/transactions`,
        'Get account transactions'
      );
    }
  } catch (error) {
    console.log(`${colors.yellow}Skipping account-specific tests${colors.reset}\n`);
  }

  // ============ IMMOBILISATIONS ============
  console.log(`${colors.blue}========== IMMOBILISATIONS ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/immobilisations', 'Get all fixed assets');
  await testEndpoint(
    'GET',
    '/api/immobilisations/statistiques',
    'Get immobilisations statistics'
  );

  // ============ DOCUMENTS COMPTABLES ============
  console.log(`${colors.blue}========== DOCUMENTS COMPTABLES ENDPOINTS ==========${colors.reset}`);
  await testEndpoint(
    'GET',
    '/api/documents/journal?dateDebut=2025-01-01&dateFin=2025-12-31',
    'Get journal comptable'
  );
  await testEndpoint(
    'GET',
    '/api/documents/grand-livre?dateDebut=2025-01-01&dateFin=2025-12-31',
    'Get grand livre'
  );
  await testEndpoint('GET', '/api/documents/bilan?date=2025-12-31', 'Get balance sheet');
  await testEndpoint(
    'GET',
    '/api/documents/compte-resultat?dateDebut=2025-01-01&dateFin=2025-12-31',
    'Get income statement'
  );

  // ============ ENTREPRISE ============
  console.log(`${colors.blue}========== ENTREPRISE ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/entreprise', 'Get company info');

  // ============ COMPTABILITE ============
  console.log(`${colors.blue}========== COMPTABILITE ENDPOINTS ==========${colors.reset}`);
  await testEndpoint('GET', '/api/comptabilite/comptes', 'Get accounting plan');

  // ============ SUMMARY ============
  console.log('='.repeat(50));
  console.log('           TEST SUMMARY');
  console.log('='.repeat(50));
  console.log(`Total Tests:  ${colors.blue}${totalTests}${colors.reset}`);
  console.log(`Passed:       ${colors.green}${passedTests}${colors.reset}`);
  console.log(`Failed:       ${colors.red}${failedTests}${colors.reset}`);

  if (failedTests > 0) {
    console.log(`\n${colors.red}Failed endpoints:${colors.reset}`);
    failedEndpoints.forEach((endpoint) => {
      console.log(`  - ${endpoint}`);
    });
  }

  console.log('');

  if (failedTests === 0) {
    console.log(`${colors.green}✓ All tests passed!${colors.reset}`);
    process.exit(0);
  } else {
    console.log(`${colors.red}✗ Some tests failed!${colors.reset}`);
    process.exit(1);
  }
}

// Run tests
runAllTests().catch((error) => {
  console.error(`${colors.red}Fatal error:${colors.reset}`, error);
  process.exit(1);
});
