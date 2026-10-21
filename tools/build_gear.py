"""Build GearFinder's offline Forever snapshot. Run with --refresh to update it.

Public JSON is cached under work/gear. No game files are changed by this tool.
Classic source records retain their provenance and GPL-3.0 notice.
"""
import argparse
import collections
import concurrent.futures
import datetime
import hashlib
import html
import json
from pathlib import Path
import re
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'work' / 'gear'
OUT = ROOT if (ROOT / 'GearFinder.toc').exists() else ROOT / 'GearFinder'
BASE = 'https://forever-codex.com'
REFRESH = False


def fetch(name, path, optional=False):
    file = CACHE / name
    if REFRESH or not file.exists():
        try:
            request = urllib.request.Request(BASE + path, headers={'User-Agent': 'GearFinderPersonalImport/1.0'})
            data = urllib.request.urlopen(request, timeout=45).read()
        except urllib.error.HTTPError as error:
            if optional and error.code == 404:
                return None
            raise
        file.write_bytes(data)
    return file.read_text(encoding='utf-8')


def data(name, path, optional=False):
    raw = fetch(name, path, optional)
    return json.loads(raw) if raw else {}


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r') + '"'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items() if v is not None) + '}'
    raise TypeError(type(value))


def main():
    global REFRESH
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh', action='store_true')
    REFRESH = parser.parse_args().refresh
    CACHE.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(exist_ok=True)
    gear = data('gear.json', '/data/gear/items.json')
    text = data('text.json', '/data/gear/text.en.json')
    qindex = data('quests.json', '/data/quests/list.json')
    cqindex = data('classicquests.json', '/data/classicdb/quest-log.json')
    assert gear['layout'][:10] == ['id', 'name', 'quality', 'itemLevel', 'reqLevel', 'slot', 'class', 'subclass', 'icon', 'stats']
    assert gear['build'] == qindex['build'], 'Mixed builds. Refresh the snapshot.'
    dungeon_html = fetch('dungeons.html', '/dungeons/')
    dungeons = {}
    for row in re.findall(r'<li class="df-row\b.*?</li>', dungeon_html, re.S):
        if 'data-type="dungeon"' not in row:
            continue
        path = re.search(r'href="/dungeons/([^/]+)/', row)
        low = re.search(r'data-min="(\d+)"', row)
        high = re.search(r'data-max="(\d+)"', row)
        title = re.search(r'class="df-title"[^>]*>(.*?)</span>', row, re.S)
        if path and low and high and title:
            name = html.unescape(re.sub('<[^>]+>', '', title[1])).strip()
            dungeons[path[1]] = dict(name=name, min=int(low[1]), max=int(high[1]),
                                    new='data-show="new"' in row)
    assert len(dungeons) >= 20, 'Dungeon page format changed.'

    jobs = [('chunk' + str(n) + '.json', '/data/items/c/' + str(n) + '.json', False)
            for n in sorted({r[0] // 500 for r in gear['items']})]
    jobs += [('classic-items-' + str(n) + '.json', '/data/classicdb/items/' + str(n) + '.json', True)
             for n in sorted({r[0] // 250 for r in gear['items'] if r[0] < 25000})]
    jobs += [('classic-quests-' + str(n) + '.json', '/data/classicdb/quests/' + str(n) + '.json', True)
             for n in sorted({r[0] // 250 for r in cqindex['rows']})]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        downloaded = list(pool.map(lambda job: data(*job), jobs))
    entries, classic, quests, places = {}, {}, {}, {}
    for job, chunk in zip(jobs, downloaded):
        if job[0].startswith('chunk'):
            assert chunk['build'] == gear['build'], 'Mixed item builds. Refresh the snapshot.'
            entries.update(chunk['items'])
        elif job[0].startswith('classic-items'):
            places.update(chunk.get('pl', {}))
            for item_id, record in chunk.get('items', {}).items():
                classic[item_id] = (record, chunk)
        else:
            for quest_id, q in chunk.get('q', {}).items():
                quests[int(quest_id)] = dict(id=int(quest_id), name=q['t'][0], min=q['ml'],
                    level=q['lv'], faction={'A': 'Alliance', 'H': 'Horde'}.get(q.get('s')),
                    classMask=q.get('cl'), raceMask=q.get('rm'), previous=q.get('pr'),
                    kind=q['k'], classic=True, repeatable=bool(q.get('rp')),
                    zone=q.get('z'), skill=q.get('sk'), requirements=bool(q.get('rr') or q.get('ro') or q.get('bc')))
    for r in qindex['rows']:
        q = quests.setdefault(r[0], dict(id=r[0]))
        q.update(name=r[1] or r[2], level=r[4], min=r[5], kind=r[7], classic=False,
                 faction='Alliance' if r[8] & 64 else 'Horde' if r[8] & 128 else None,
                 denied=bool(r[8] & 256))
        if len(r) > 11 and r[11]:
            q['classMask'] = 2 ** (r[11] - 1)
        if r[6] >= 0:
            zone = qindex['zones'][r[6]]
            q['zone'] = zone[1]
            if zone[5] == 'dungeon':
                q['dungeon'] = zone[0]

    records, counts, used_quests = [], collections.Counter(), set()
    for r in gear['items']:
        r = r + [0] * (19 - len(r))
        item_id = str(r[0])
        e = entries[item_id]
        extra = r[18] if len(r) > 18 and isinstance(r[18], dict) else {}
        flags = r[15] if len(r) > 15 else 0
        if r[2] < 1 or flags & 6 or r[5] in (0, 4, 19, 18):
            continue
        sources = []
        for s in e.get('s', []):
            if s['k'] == 'c':
                sources.append(dict(kind='craft', name=s['p'].replace('-', ' ').title(),
                    profession=s['p'], spell=s['r'], skill=s.get('sk') or None,
                    how=s.get('how'), recipes=s.get('by', []), classic=False))
            elif s['k'] == 'q':
                used_quests.add(s['id'])
                sources.append(dict(kind='quest', name=s['t']['en'], quest=s['id'],
                    classic=False, choice=bool(s.get('ch'))))
        ci, chunk = classic.get(item_id, ({}, {}))
        for drop in ci.get('d', []):
            npc = chunk.get('npcs', {}).get(str(drop['n']), {})
            place = places.get(npc.get('z'), {})
            if place.get('k') != 'd' or drop.get('q'):
                continue
            slug = place.get('p', '').split('/')[-1]
            sources.append(dict(kind='dungeon', name=place['n'][0], boss=npc['n'][0],
                npc=drop['n'], dungeon=slug, chance=drop.get('p'), classic=True))
        # Some encounter creatures have no spawn coordinates. The source index
        # still identifies their dungeon, so retain that documented boss route.
        cx = e.get('cx', {})
        if cx.get('k') in ('b', 'x'):
            match = re.match(r'^(.*?) \(([^()]+)\)$', cx.get('t', {}).get('en', ''))
            if match:
                boss, zone = match.groups()
                normalize = lambda name: name.lower().removeprefix('the ')
                slug = next((key for key, d in dungeons.items() if normalize(d['name']) == normalize(zone)), None)
                if slug and not any(s.get('boss') == boss and s.get('dungeon') == slug for s in sources):
                    sources.append(dict(kind='dungeon', name=zone, boss=boss, dungeon=slug,
                                        chance=cx.get('n'), classic=True))
        for qr in ci.get('qr', []):
            if not any(s.get('quest') == qr['id'] for s in sources):
                used_quests.add(qr['id'])
                sources.append(dict(kind='quest', name=qr['t'][0], quest=qr['id'], classic=True))
        stats = {int(k): v for k, v in (r[9] or [])}
        effects = [dict(trigger=fx[0], text=text['fx'].get(str(fx[1]), 'Effect ' + str(fx[1])))
                   for fx in (r[12] or [])]
        record = dict(id=r[0], name=r[1][0] if isinstance(r[1], list) else r[1], quality=r[2],
            ilvl=r[3], level=r[4], slot=r[5], classID=r[6], sub=r[7], icon=r[8], stats=stats,
            armor=r[10] or 0, damage=r[11] or None, effects=effects, setID=r[13],
            classMask=r[14], flags=flags, bind=r[16] if len(r)>16 else 0, sources=sources,
            random=bool(extra.get('sx')), requiredSkill=extra.get('rs'),
            specialRequirements=bool(extra.get('rp') or extra.get('lc') or extra.get('zn') or extra.get('pr')))
        records.append(record)
        for kind in {s['kind'] for s in sources}:
            counts[kind] += 1
    # Keep prerequisite records too. These are useful even without an equipment reward.
    summary = dict(build=gear['build'], imported=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   count=len(records), sourced=sum(bool(r['sources']) for r in records), counts=dict(counts),
                   source=BASE + '/items/', classicSource=cqindex['src'])
    lines = ['-- Generated by tools/build_gear.py. See SOURCES.md for provenance.', 'local _, G = ...',
             'G.dataInfo = ' + lua(summary), 'G.dungeons = ' + lua(dungeons),
             'G.quests = ' + lua(quests), 'G.items = {']
    lines += [lua(record) + ',' for record in records]
    lines.append('}')
    content = '\n'.join(lines) + '\n'
    temp = OUT / 'Data.lua.tmp'
    temp.write_text(content, encoding='utf-8')
    temp.replace(OUT / 'Data.lua')
    (CACHE / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    manifest = {file.name: hashlib.sha256(file.read_bytes()).hexdigest() for file in CACHE.glob('*.json')}
    (OUT / 'snapshot-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    for name in ['NOTICE.md', 'LICENSE.md', 'COPYRIGHT.md', 'AUTHORS.txt']:
        content = fetch('classic-' + name, '/data/classicdb/' + name)
        (OUT / ('CLASSICDB-' + name)).write_text(content, encoding='utf-8')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
