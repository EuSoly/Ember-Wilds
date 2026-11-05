import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

// Imagens públicas de referência (acessórios, mochilas, livros, caixas, mãos das skins). Executar a partir da raiz do projeto.
// Cobertura numérica não é inventário oficial da loja.
const MAX_ID = 250;
const CATEGORIES = [
  { key: 'accessory', folder: 'acessorios' },
  { key: 'bag', folder: 'mochilas' },
  { key: 'book', folder: 'livros' },
  { key: 'crate', folder: 'caixas' },
  { key: 'hand-skin', folder: 'maos', maxId: 300 }, // mão de cada skin de corpo, mesmo ID da skin
];
// Filtro opcional: node scripts/catalog-cosmetic-references.mjs hand-skin crate
const only = process.argv.slice(2);
const base = path.resolve('assets/skins/reference');
const changelog = await fs.readFile(path.join(base, 'changelog.html'), 'utf8');

for (const { key, folder, maxId = MAX_ID } of CATEGORIES) {
  if (only.length && !only.includes(key)) continue;
  const root = path.join(base, folder);
  await fs.mkdir(path.join(root, 'images'), { recursive: true });
  const labels = new Map();
  for (const tag of changelog.matchAll(/<img\b[^>]*>/gi)) {
    const id = tag[0].match(new RegExp(`day-${key}(\\d+)\\.png`));
    const alt = tag[0].match(/alt="([^"]+)"/);
    if (id && alt) labels.set(Number(id[1]), alt[1]);
  }
  const jobs = [];
  for (let id = 0; id <= maxId; id++) for (const variant of ['day', 'night']) jobs.push({ id, variant });
  const results = [];
  let cursor = 0;
  async function worker() {
    while (cursor < jobs.length) {
      const { id, variant } = jobs[cursor++];
      const filename = `${variant}-${key}${id}.png`;
      const url = `https://starve.io/img/${filename}`;
      let record;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
          record = { id, variant, url, status: response.status };
          if (response.ok) {
            const data = Buffer.from(await response.arrayBuffer());
            if (data.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Not PNG');
            Object.assign(record, { file: `images/${filename}`, width: data.readUInt32BE(16), height: data.readUInt32BE(20), bytes: data.length, sha256: crypto.createHash('sha256').update(data).digest('hex') });
            await fs.writeFile(path.join(root, record.file), data);
          }
          if (response.status >= 500 || response.status === 429) throw new Error(`HTTP ${response.status}`);
          break;
        } catch (error) { record = { id, variant, url, error: String(error) }; }
      }
      results.push(record);
    }
  }
  await Promise.all(Array.from({ length: 6 }, worker));
  results.sort((a, b) => a.id - b.id || a.variant.localeCompare(b.variant));
  const items = [];
  for (let id = 0; id <= maxId; id++) {
    const assets = results.filter(r => r.id === id && r.file);
    if (assets.length) items.push({ id, sourceLabel: labels.get(id) ?? null, nameVerified: false, rarity: null, assets });
  }
  const catalog = { category: key, checkedAt: new Date().toISOString(), source: 'https://starve.io/', labelSource: 'https://starve.io/changelog.html', checkedRange: [0, maxId], completeness: 'All accessible day/night images in checked numeric range; not verified against the live cosmetics inventory.', itemCount: items.length, imageCount: results.filter(r => r.file).length, items, unavailable: results.filter(r => !r.file) };
  await fs.writeFile(path.join(root, 'catalog.json'), JSON.stringify(catalog, null, 2) + '\n');
  const csv = ['"Id","RotuloFonte","ImagemDia","ImagemNoite"', ...items.map(i => {
    const day = i.assets.find(a => a.variant === 'day')?.file ?? '';
    const night = i.assets.find(a => a.variant === 'night')?.file ?? '';
    return `"${i.id}",${i.sourceLabel ? `"${i.sourceLabel.replace(/"/g, '""')}"` : ''},"${day}","${night}"`;
  })];
  await fs.writeFile(path.join(root, 'catalog.csv'), csv.join('\n') + '\n');
  const ids = items.map(i => i.id);
  console.log(JSON.stringify({ category: key, items: items.length, images: catalog.imageCount, first: ids[0], last: ids.at(-1), gaps: Array.from({ length: (ids.at(-1) ?? -1) + 1 }, (_, i) => i).filter(i => !ids.includes(i)), errors: catalog.unavailable.filter(r => r.error).length, labels: items.filter(i => i.sourceLabel).length }));
}
