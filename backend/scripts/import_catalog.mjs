import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import process from 'node:process';

const args = new Map(
  process.argv.slice(2).map((argument) => {
    const [key, ...rest] = argument.split('=');
    return [key, rest.length === 0 ? true : rest.join('=')];
  }),
);

const catalogPath = resolve(
  String(args.get('--file') ?? '../frontend/assets/data/government_schemes.json'),
);
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));

const sections = [
  'All Schemes',
  'Scheme Info',
  'Documents Required',
  'Services Required',
];
for (const section of sections) {
  if (!Array.isArray(catalog[section])) {
    throw new Error(`Catalog section "${section}" must be an array.`);
  }
}

const counts = {
  schemes: catalog['Scheme Info'].length,
  eligibility: catalog['All Schemes'].length,
  documents: catalog['Documents Required'].length,
  services: catalog['Services Required'].length,
};

const codeByName = new Map(
  catalog['All Schemes'].map((row) => [row['Scheme Name'], row['Scheme ID']]),
);
for (const row of catalog['Scheme Info']) {
  if (!/^IN\d{3}$/.test(row['Scheme Code'] ?? '')) {
    row['Scheme Code'] = codeByName.get(row['Scheme Name']) ?? row['Scheme Code'];
  }
}
const codes = catalog['Scheme Info'].map((row) => row['Scheme Code']);
if (codes.some((code) => !/^IN\d{3}$/.test(code ?? ''))) {
  throw new Error('Every Scheme Info row must use a stable IN000 scheme code.');
}
if (new Set(codes).size !== codes.length) {
  throw new Error('Scheme codes must be unique.');
}
if (counts.schemes === 0 || counts.eligibility !== counts.schemes) {
  throw new Error('Scheme Info and All Schemes must be non-empty and have equal counts.');
}

for (const [argument, actual] of [
  ['--expect-schemes', counts.schemes],
  ['--expect-documents', counts.documents],
  ['--expect-services', counts.services],
]) {
  if (args.has(argument) && Number(args.get(argument)) !== actual) {
    throw new Error(`${argument} expected ${args.get(argument)}, received ${actual}.`);
  }
}

console.log('Catalog validation complete:', counts);
if (args.get('--validate-only') === true) process.exit(0);

const projectUrl = process.env.SUPABASE_URL?.replace(/\/$/, '');
const secretKey = process.env.SUPABASE_SECRET_KEY;
if (!projectUrl || !secretKey) {
  throw new Error(
    'Set SUPABASE_URL and SUPABASE_SECRET_KEY. Never place the secret key in source control.',
  );
}

async function rpc(name, body) {
  const response = await fetch(`${projectUrl}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: {
      apikey: secretKey,
      authorization: `Bearer ${secretKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const responseText = await response.text();
  if (!response.ok) {
    throw new Error(`${name} failed (${response.status}): ${responseText}`);
  }
  return responseText.length === 0 ? null : JSON.parse(responseText);
}

const imported = await rpc('admin_import_scheme_catalog', { catalog });
console.log('Catalog import complete:', imported);

if (args.get('--publish') === true) {
  const published = await rpc('admin_publish_scheme_catalog', {
    notes: String(args.get('--notes') ?? 'Initial 217-scheme catalog import'),
    allow_large_drop: false,
  });
  console.log('Catalog release published:', {
    id: published?.id,
    version: published?.version,
    scheme_count: published?.scheme_count,
    document_count: published?.document_count,
    service_count: published?.service_count,
    sha256: published?.sha256,
  });
}
