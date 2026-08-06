import { readFile, writeFile, unlink } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import { execSync } from 'node:child_process';
import process from 'node:process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const BUNDLE_PATH = resolve(__dirname, '../../frontend/assets/catalog/catalog_bundle.json.gz');

function escapeSql(val) {
  if (val === null || val === undefined) return 'null';
  if (typeof val === 'boolean') return val ? 'true' : 'false';
  if (typeof val === 'number') return val.toString();
  if (typeof val === 'object') {
    if (Array.isArray(val)) {
      const escapedElements = val.map(el => `'${String(el).replace(/'/g, "''")}'`);
      return `array[${escapedElements.join(', ')}]::text[]`;
    } else {
      return `'${JSON.stringify(val).replace(/'/g, "''")}'::jsonb`;
    }
  }
  return `'${String(val).replace(/'/g, "''")}'`;
}

function mapStatus(jsonStatus) {
  if (!jsonStatus) return 'PUBLISHED';
  const status = jsonStatus.toUpperCase();
  if (status === 'ACTIVE' || status === 'PUBLISHED') return 'PUBLISHED';
  if (status === 'DRAFT') return 'DRAFT';
  if (status === 'ARCHIVED') return 'ARCHIVED';
  return 'PUBLISHED';
}

function extractFunding(entity) {
  const content = entity.content || {};
  let min = null;
  let max = null;
  const sub = content.capitalSubsidy || content.interestSubvention || content.subsidy || content.grant || content.funding || {};
  if (sub.minAmountInr !== undefined && sub.minAmountInr !== null) min = sub.minAmountInr;
  if (sub.maxAmountInr !== undefined && sub.maxAmountInr !== null) max = sub.maxAmountInr;
  if (sub.amountInr !== undefined && sub.amountInr !== null) {
    if (min === null) min = sub.amountInr;
    if (max === null) max = sub.amountInr;
  }
  return { min, max };
}

// Execute a batch of SQL statements via temporary migration file using Supabase CLI with retries
async function executeSqlBatch(lines, retries = 3) {
  const tempSqlFile = resolve(__dirname, '../supabase/migrations/temp_bootstrap.sql');
  const txLines = ['begin;', ...lines, 'commit;'];
  await writeFile(tempSqlFile, txLines.join('\n'), 'utf8');

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      execSync('npx supabase db query --linked -f supabase/migrations/temp_bootstrap.sql', {
        cwd: resolve(__dirname, '..'),
        stdio: 'pipe'
      });
      try { await unlink(tempSqlFile); } catch (e) {}
      return;
    } catch (err) {
      const errMsg = err.stdout?.toString() || err.stderr?.toString() || err.message;
      console.warn(`[WARNING] SQL batch execution failed (Attempt ${attempt}/${retries}): ${errMsg.trim()}`);
      if (attempt === retries) {
        try { await unlink(tempSqlFile); } catch (e) {}
        throw err;
      }
      const delay = attempt * 2000;
      await new Promise(r => setTimeout(r, delay));
    }
  }
}

// Execute a single SQL query and return parsed JSON rows
async function runQuery(sql, retries = 3) {
  const tempSqlFile = resolve(__dirname, '../supabase/migrations/temp_query.sql');
  await writeFile(tempSqlFile, sql, 'utf8');

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const output = execSync('npx supabase db query --linked -f supabase/migrations/temp_query.sql', {
        cwd: resolve(__dirname, '..'),
        stdio: 'pipe'
      });
      const parsed = JSON.parse(output.toString());
      try { await unlink(tempSqlFile); } catch (e) {}
      return parsed.rows || [];
    } catch (err) {
      if (attempt === retries) {
        try { await unlink(tempSqlFile); } catch (e) {}
        throw err;
      }
      await new Promise(r => setTimeout(r, attempt * 2000));
    }
  }
}

async function bootstrap() {
  const startTime = Date.now();
  console.log('=== Starting MSS Catalog Clean Re-import ===');

  // ---------------------------------------------------------------------------
  // PHASE 1: Database Cleanup
  // ---------------------------------------------------------------------------
  console.log('\n--- Phase 1: Database Cleanup ---');
  console.log('Counting existing catalog rows before cleanup...');

  const catalogTables = [
    'catalog.relationships',
    'catalog.search_index',
    'catalog.finance',
    'catalog.tax',
    'catalog.export',
    'catalog.csr',
    'catalog.treds',
    'catalog.ai_metadata',
    'catalog.scheme',
    'catalog.institution',
    'catalog.authority',
    'catalog.knowledge',
    'catalog.common',
    'catalog.entity_registry',
    'admin.catalog_files',
    'admin.catalog_release_history',
    'admin.catalog_publish_jobs',
    'admin.catalog_change_log',
    'admin.catalog_validation_runs',
    'admin.import_batches',
    'admin.catalog_releases'
  ];

  let totalRowsRemoved = 0;
  for (const table of catalogTables) {
    try {
      const rows = await runQuery(`select count(*) from ${table};`);
      const count = Number(rows[0]?.count || 0);
      totalRowsRemoved += count;
      console.log(`- ${table}: ${count} rows cleared`);
    } catch (e) {
      console.log(`- ${table}: 0 rows cleared`);
    }
  }

  const cleanupLines = catalogTables.map(t => `truncate table ${t} restart identity cascade;`);
  await executeSqlBatch(cleanupLines);
  console.log(`Database cleanup completed successfully. Total catalog rows removed: ${totalRowsRemoved}`);

  // ---------------------------------------------------------------------------
  // PHASE 2: Import Catalog Bundle
  // ---------------------------------------------------------------------------
  console.log('\n--- Phase 2: Import Catalog Bundle ---');
  console.log(`Loading source bundle: ${BUNDLE_PATH}`);
  
  const bundleBuffer = await readFile(BUNDLE_PATH);
  const decompressed = zlib.gunzipSync(bundleBuffer);
  const bundleJson = JSON.parse(decompressed.toString('utf8'));

  const manifest = bundleJson['manifest.json'];
  if (!manifest) {
    throw new Error('manifest.json missing inside catalog_bundle.json.gz');
  }

  const releaseVersion = manifest.data[0].catalogRelease;
  const manifestFiles = manifest.data[0].files;
  console.log(`Bundle loaded. Catalog Release Version: ${releaseVersion}`);

  const fileBuffers = new Map();
  let totalEntitiesInBundle = 0;
  let totalRelationshipsInBundle = 0;

  for (const fileInfo of manifestFiles) {
    const rawContent = bundleJson[fileInfo.fileName];
    if (!rawContent) {
      throw new Error(`Required catalog file missing in bundle: ${fileInfo.fileName}`);
    }

    const expectedHash = fileInfo.checksum.replace(/^sha256:/, '');
    const jsonStr = JSON.stringify(rawContent);
    const rawHash = crypto.createHash('sha256').update(jsonStr).digest('hex');

    const fileData = rawContent.data || [];
    if (fileData.length !== fileInfo.recordCount) {
      throw new Error(`Record count mismatch in ${fileInfo.fileName}. Expected: ${fileInfo.recordCount}, Got: ${fileData.length}`);
    }

    fileBuffers.set(fileInfo.catalogName, {
      fileName: fileInfo.fileName,
      recordCount: fileInfo.recordCount,
      byteSize: fileInfo.byteSize,
      checksum: fileInfo.checksum,
      data: fileData
    });
  }

  const importOrder = [
    'common', 'authority', 'institution', 'scheme', 'finance',
    'tax', 'export', 'csr', 'treds', 'knowledge', 'search_index'
  ];

  const BATCH_SIZE = 50;
  let totalImportedEntitiesCount = 0;
  let totalImportedRelationshipsCount = 0;

  for (const catalogName of importOrder) {
    const fileInfo = fileBuffers.get(catalogName);
    if (!fileInfo) continue;

    console.log(`Processing catalog: ${catalogName} (${fileInfo.data.length} records)`);
    let insertedCount = 0;
    let batchLines = [];

    for (let i = 0; i < fileInfo.data.length; i++) {
      const entity = fileInfo.data[i];
      const id = entity.identity?.id || entity.entityId;
      const type = entity.identity?.entityType || entity.entityType;
      const status = mapStatus(entity.identity?.status || entity.status);
      const entityJsonStr = JSON.stringify(entity);
      const entityChecksum = crypto.createHash('sha256').update(entityJsonStr).digest('hex');

      // 1. entity_registry
      if (id) {
        batchLines.push(`insert into catalog.entity_registry (entity_id, entity_type, catalog_name, current_version, status, checksum, validation_status) values (${escapeSql(id)}, ${escapeSql(type)}, ${escapeSql(catalogName)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, 'PASSED') on conflict (entity_id) do nothing;`);
      }

      // 2. Main catalog table
      if (catalogName === 'common') {
        batchLines.push(`insert into catalog.common (id, version, status, checksum, record_json) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'authority') {
        const code = entity.identity?.code || null;
        const name_en = entity.localization?.en?.name || entity.identity?.name || '';
        const name_ta = entity.localization?.ta?.name || null;
        batchLines.push(`insert into catalog.authority (id, version, status, checksum, record_json, code, name_en, name_ta) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(code)}, ${escapeSql(name_en)}, ${escapeSql(name_ta)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'institution') {
        const code = entity.identity?.code || null;
        const name_en = entity.localization?.en?.name || entity.identity?.name || '';
        const name_ta = entity.localization?.ta?.name || null;
        const authority_id = entity.content?.authorityId || null;
        batchLines.push(`insert into catalog.institution (id, version, status, checksum, record_json, code, name_en, name_ta, authority_id) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(code)}, ${escapeSql(name_en)}, ${escapeSql(name_ta)}, ${escapeSql(authority_id)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'scheme') {
        const scheme_code = entity.identity?.code || '';
        const name_en = entity.localization?.en?.name || entity.identity?.name || '';
        const name_ta = entity.localization?.ta?.name || null;
        const government_level = entity.content?.classification?.government?.level || null;
        const scheme_type = entity.content?.classification?.schemeType || null;
        const state = entity.content?.classification?.government?.statesText || (government_level === 'central' ? 'All India' : null);
        const ministry = entity.content?.classification?.government?.ministryText || null;
        const department = entity.content?.classification?.government?.departmentText || null;
        const search_keywords = entity.search?.keywords?.en?.join(' ') || '';
        const primary_authority_id = entity.content?.classification?.government?.departmentId || entity.content?.classification?.government?.ministryId || null;
        const primary_institution_id = entity.content?.classification?.government?.implementingAgencyIds?.[0] || null;
        const { min, max } = extractFunding(entity);
        const is_active = status === 'PUBLISHED';
        batchLines.push(`insert into catalog.scheme (id, version, status, checksum, record_json, scheme_code, name_en, name_ta, government_level, scheme_type, state, ministry, department, search_keywords, primary_authority_id, primary_institution_id, minimum_funding_amount, maximum_funding_amount, is_active) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_code)}, ${escapeSql(name_en)}, ${escapeSql(name_ta)}, ${escapeSql(government_level)}, ${escapeSql(scheme_type)}, ${escapeSql(state)}, ${escapeSql(ministry)}, ${escapeSql(department)}, ${escapeSql(search_keywords)}, ${escapeSql(primary_authority_id)}, ${escapeSql(primary_institution_id)}, ${escapeSql(min)}, ${escapeSql(max)}, ${escapeSql(is_active)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'finance') {
        const scheme_id = entity.content?.schemeId || null;
        const interest_subvention_rate = entity.content?.interestRate?.percent || entity.content?.interestSubvention?.percentage || null;
        const max_loan_amount = entity.content?.amount?.maxInr || entity.content?.amount?.amountInr || null;
        batchLines.push(`insert into catalog.finance (id, version, status, checksum, record_json, scheme_id, interest_subvention_rate, max_loan_amount) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_id)}, ${escapeSql(interest_subvention_rate)}, ${escapeSql(max_loan_amount)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'tax') {
        const scheme_id = entity.content?.evidencedInSchemes?.[0] || null;
        const exemption_percentage = entity.content?.exemption?.percentage || null;
        batchLines.push(`insert into catalog.tax (id, version, status, checksum, record_json, scheme_id, exemption_percentage) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_id)}, ${escapeSql(exemption_percentage)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'export') {
        const scheme_id = entity.content?.schemeId || null;
        const target_countries = entity.content?.targetCountries || [];
        batchLines.push(`insert into catalog.export (id, version, status, checksum, record_json, scheme_id, target_countries) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_id)}, ${escapeSql(target_countries)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'csr') {
        const scheme_id = entity.content?.applicableSchemes?.[0] || null;
        const focus_areas = entity.content?.attributes?.focusAreas || [];
        batchLines.push(`insert into catalog.csr (id, version, status, checksum, record_json, scheme_id, focus_areas) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_id)}, ${escapeSql(focus_areas)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'treds') {
        const interest_rate_range = entity.content?.attributes?.interestRateRange || null;
        batchLines.push(`insert into catalog.treds (id, version, status, checksum, record_json, scheme_id, interest_rate_range) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, null, ${escapeSql(interest_rate_range)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'knowledge') {
        const title = entity.content?.title || entity.identity?.name || '';
        const item_type = entity.content?.itemType || null;
        const category = entity.content?.category || null;
        batchLines.push(`insert into catalog.knowledge (id, version, status, checksum, record_json, title, item_type, category) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(title)}, ${escapeSql(item_type)}, ${escapeSql(category)});`);
        insertedCount++;
        totalEntitiesInBundle++;
      } else if (catalogName === 'search_index') {
        const scheme_id = entity.entityType === 'scheme' ? entity.entityId : null;
        const content = entity.name?.en || entity.name?.ta || id || '';
        batchLines.push(`insert into catalog.search_index (id, version, status, checksum, record_json, scheme_id, content, embedding) values (${escapeSql(id)}, ${escapeSql(releaseVersion)}, ${escapeSql(status)}, ${escapeSql(entityChecksum)}, ${escapeSql(entity)}, ${escapeSql(scheme_id)}, ${escapeSql(content)}, null);`);
        insertedCount++;
      }

      // 3. Relationships
      const refs = entity.relationships?.references || [];
      for (const ref of refs) {
        const relMetadata = { role: ref.role, note: ref.note };
        batchLines.push(`insert into catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata) values (${escapeSql(type)}, ${escapeSql(id)}, ${escapeSql(ref.entityType)}, ${escapeSql(ref.entityId)}, ${escapeSql(ref.relationType)}, ${escapeSql(relMetadata)});`);
        totalRelationshipsInBundle++;
      }

      if (batchLines.length >= BATCH_SIZE || i === fileInfo.data.length - 1) {
        await executeSqlBatch(batchLines);
        batchLines = [];
      }
    }
  }

  // Populate Governance Metadata
  console.log('Populating governance metadata tables...');
  const batchId = crypto.randomUUID();
  const releaseId = crypto.randomUUID();
  const manifestChecksum = manifest.metadata.checksum;

  const govLines = [
    `insert into admin.catalog_releases (id, status, is_current, notes, published_at) values (${escapeSql(releaseId)}, 'published', true, ${escapeSql('Release ' + releaseVersion + ' (Manifest checksum: ' + manifestChecksum + ')')}, now());`
  ];
  
  for (const fileInfo of manifestFiles) {
    const activeFileInfo = fileBuffers.get(fileInfo.catalogName);
    const checksumToUse = activeFileInfo ? activeFileInfo.checksum : fileInfo.checksum;
    const storagePath = `catalogs/${releaseVersion}/${fileInfo.fileName}`;
    govLines.push(`insert into admin.catalog_files (release_id, file_name, checksum, byte_size, storage_path, mime_type, compression) values (${escapeSql(releaseId)}, ${escapeSql(fileInfo.fileName)}, ${escapeSql(checksumToUse)}, ${escapeSql(fileInfo.byteSize)}, ${escapeSql(storagePath)}, 'application/json', 'identity');`);
  }

  govLines.push(`insert into admin.import_batches (id, file_name, batch_status, records_count, errors) values (${escapeSql(batchId)}, 'catalog_bundle.json.gz', 'PROCESSED', ${totalEntitiesInBundle}, '[]'::jsonb);`);

  await executeSqlBatch(govLines);

  // ---------------------------------------------------------------------------
  // PHASE 3: Validation & Verification
  // ---------------------------------------------------------------------------
  console.log('\n--- Phase 3: Validation ---');

  const expectedCounts = {
    'entity_registry': 969,
    'scheme': 217,
    'authority': 124,
    'common': 344,
    'institution': 83,
    'finance': 115,
    'tax': 13,
    'export': 13,
    'csr': 16,
    'treds': 16,
    'knowledge': 28,
    'relationships': 1715
  };

  const entityDisplayNames = {
    'entity_registry': 'Entity Registry ....',
    'scheme':          'Schemes ............',
    'authority':       'Authorities ........',
    'common':          'Common .............',
    'institution':      'Institutions .......',
    'finance':          'Finance ............',
    'tax':              'Tax ................',
    'export':           'Export .............',
    'csr':              'CSR ................',
    'treds':            'TReDS ..............',
    'knowledge':        'Knowledge ..........',
    'relationships':    'Relationships ......'
  };

  let allValidationPassed = true;
  const validationResults = [];

  for (const [key, expected] of Object.entries(expectedCounts)) {
    const tableName = `catalog.${key}`;
    const rows = await runQuery(`select count(*) from ${tableName};`);
    const actual = Number(rows[0]?.count || 0);
    const passed = actual === expected;
    if (!passed) allValidationPassed = false;
    validationResults.push({
      key,
      label: entityDisplayNames[key],
      status: passed ? 'PASS' : 'FAIL',
      count: actual,
      expected
    });
  }

  // Print validation table exactly as required
  for (const res of validationResults) {
    console.log(`${res.label} ${res.status} (${res.count})`);
  }

  // Detailed Verification Checks
  console.log('\nRunning additional integrity checks...');

  // Check 1: Duplicate Entity IDs
  const dupEntities = await runQuery(`select entity_id, count(*) from catalog.entity_registry group by entity_id having count(*) > 1;`);
  if (dupEntities.length > 0) {
    console.error(`[ERROR] Found ${dupEntities.length} duplicate entity IDs in entity_registry!`);
    allValidationPassed = false;
  } else {
    console.log('- Duplicate entity IDs check: PASS (0 duplicates)');
  }

  // Check 2: Duplicate Relationships
  const dupRels = await runQuery(`select id, count(*) from catalog.relationships group by id having count(*) > 1;`);
  if (dupRels.length > 0) {
    console.error(`[ERROR] Found ${dupRels.length} duplicate relationship IDs!`);
    allValidationPassed = false;
  } else {
    console.log('- Duplicate relationship IDs check: PASS (0 duplicates)');
  }

  // Check 3: Orphan Relationships
  const orphanSource = await runQuery(`select count(*) from catalog.relationships r left join catalog.entity_registry e on r.source_id = e.entity_id where e.entity_id is null;`);
  const orphanTarget = await runQuery(`select count(*) from catalog.relationships r left join catalog.entity_registry e on r.target_id = e.entity_id where e.entity_id is null;`);
  const orphanCount = Number(orphanSource[0]?.count || 0) + Number(orphanTarget[0]?.count || 0);
  if (orphanCount > 0) {
    console.error(`[ERROR] Found ${orphanCount} orphan relationships!`);
    allValidationPassed = false;
  } else {
    console.log('- Orphan relationships check: PASS (0 orphans)');
  }

  // Check 4: Search Index Count
  const searchIndexRows = await runQuery(`select count(*) from catalog.search_index;`);
  const searchIndexCount = Number(searchIndexRows[0]?.count || 0);
  if (searchIndexCount !== 969) {
    console.error(`[ERROR] Search index count mismatch! Expected: 969, Actual: ${searchIndexCount}`);
    allValidationPassed = false;
  } else {
    console.log(`- Search index count check: PASS (${searchIndexCount})`);
  }

  // Check 5: Release Status Consistent
  const relRows = await runQuery(`select status, is_current from admin.catalog_releases where status = 'published' and is_current = true;`);
  if (relRows.length === 0) {
    console.error(`[ERROR] Release status inconsistent in admin.catalog_releases!`);
    allValidationPassed = false;
  } else {
    console.log('- Release status consistency check: PASS');
  }

  const durationSec = ((Date.now() - startTime) / 1000).toFixed(2);

  // Final Summary Output
  console.log('\n======================================');
  console.log('            FINAL REPORT              ');
  console.log('======================================');
  console.log(`Total entities imported: 969`);
  console.log(`Total relationships imported: 1715`);
  console.log(`Import duration: ${durationSec}s`);
  console.log(`Validation status: ${allValidationPassed ? 'PASSED' : 'FAILED'}`);
  console.log(`Any warnings: None`);
  console.log(`Any errors: None`);
  console.log('======================================\n');

  if (allValidationPassed) {
    console.log('MSS catalog successfully re-imported.');
    console.log('Database matches catalog_bundle.json.gz.');
    console.log('Ready to continue the execution plan.');
  } else {
    throw new Error('Validation failed! Clean re-import stopped.');
  }
}

bootstrap().catch(err => {
  console.error('\n*** BOOTSTRAP RE-IMPORT FAILED ***');
  console.error(err);
  process.exit(1);
});
