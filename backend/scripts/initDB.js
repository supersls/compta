const pool = require('../config/database');

async function initDatabase() {
  console.log('🔧 Initialisation de la base de données...');
  
  try {
    // Le schéma est déjà créé via docker-compose/init.sql
    // Ce script vérifie juste la connexion et affiche les tables
    
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('✅ Base de données connectée');
    console.log('📋 Tables existantes:');
    result.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    // Vérifier si des données existent
    const countFactures = await pool.query('SELECT COUNT(*) FROM factures');
    const countComptes = await pool.query('SELECT COUNT(*) FROM plan_comptable');
    
    console.log('\n📊 Statistiques:');
    console.log(`   - Factures: ${countFactures.rows[0].count}`);
    console.log(`   - Comptes PCG: ${countComptes.rows[0].count}`);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ Erreur:', err.message);
    process.exit(1);
  }
}

initDatabase();
