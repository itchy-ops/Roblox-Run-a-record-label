"""Verify the town is serialized in the built place, without running any scripts."""
import xml.etree.ElementTree as ET
from pathlib import Path

root = ET.parse('build/RecordLabel.rbxlx').getroot()

def name(item):
    return item.find("Properties/string[@name='Name']").text

items = list(root.iter('Item'))
town = next(i for i in items if i.get('class') == 'Model' and name(i) == 'Town')
children = list(town.iter('Item'))
parts = [i for i in children if i.get('class') in ('Part', 'SpawnLocation')]
assert len(parts) >= 25, 'Town geometry missing from place file'
for part in parts:
    assert part.find("Properties/bool[@name='Anchored']").text == 'true'
    assert any(p.get('name') in ('CFrame', 'Size', 'size') for p in part.find('Properties'))
assert any(name(i) == 'Town Ground' for i in parts)
assert any(i.get('class') == 'SpawnLocation' for i in parts)
prompts = [i for i in children if i.get('class') == 'ProximityPrompt']
assert len(prompts) == 4, 'Discovery/studio prompts missing'
for location in ('Your Studio', 'Open Mic', 'Park Stage', 'Music Cafe'):
    assert any(name(i) == location + ' booth' for i in parts), location
for path in Path('src').rglob('*.lua'):
    expected = path.read_text()
    assert any(any(p.get('name') == 'Source' and p.text == expected for p in i.find('Properties')) for i in items), path
print(f'Place regression checks passed: {len(parts)} anchored parts, spawn, 4 prompts, and current script sources embedded before Play')
