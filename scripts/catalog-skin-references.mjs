import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

// Public reference images only. Numeric coverage is not an authoritative shop inventory.
const root = path.resolve('assets/skins/reference');
await fs.mkdir(path.join(root, 'images'), { recursive: true });
const changelog = await fs.readFile(path.join(root, 'changelog.html'), 'utf8');
const labels = new Map();
for (const tag of changelog.matchAll(/<img\b[^>]*>/gi)) {
  const id = tag[0].match(/day-skin(\d+)\.png/);
  const alt = tag[0].match(/alt="([^"]+)"/);
  if (id && alt) labels.set(Number(id[1]), alt[1]);
}
const jobs = [];
for (let id = 0; id <= 300; id++) for (const variant of ['day', 'night']) jobs.push({ id, variant });
const results = [];
let cursor = 0;
async function worker() {
  while (cursor < jobs.length) {
    const { id, variant } = jobs[cursor++];
    const filename = `${variant}-skin${id}.png`;
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
    if (results.length % 100 === 0) console.log(`Verified ${results.length}/${jobs.length}`);
  }
}
await Promise.all(Array.from({ length: 4 }, worker));
results.sort((a,b) => a.id - b.id || a.variant.localeCompare(b.variant));
const skins = [];
for (let id = 0; id <= 300; id++) {
  const assets = results.filter(r => r.id === id && r.file);
  if (assets.length) skins.push({ id, sourceLabel: labels.get(id) ?? null, nameVerified: false, rarity: null, assets });
}
const catalog = { checkedAt: new Date().toISOString(), source: 'https://starve.io/', labelSource: 'https://starve.io/changelog.html', checkedRange: [0,300], completeness: 'All accessible day/night images in checked numeric range; not verified against the live cosmetics inventory. Changelog alt labels may be generic.', skinCount: skins.length, imageCount: results.filter(r=>r.file).length, skins, unavailable: results.filter(r=>!r.file) };
await fs.writeFile(path.join(root, 'catalog.json'), JSON.stringify(catalog, null, 2) + '\n');
console.log(JSON.stringify({ skins: catalog.skinCount, images: catalog.imageCount, first: skins[0]?.id, last: skins.at(-1)?.id, missingWithinRange: Array.from({length:(skins.at(-1)?.id ?? -1)+1},(_,i)=>i).filter(id=>!skins.some(s=>s.id===id)), errors: catalog.unavailable.filter(r=>r.error), statuses: [...new Set(catalog.unavailable.map(r=>r.status))], labels: skins.filter(s=>s.sourceLabel).length }, null, 2));
