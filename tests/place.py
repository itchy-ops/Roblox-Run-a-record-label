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
ground = next(i for i in parts if name(i) == 'Town Ground')
spawn = next(i for i in parts if i.get('class') == 'SpawnLocation')
def property_node(item, name):
    return next(p for p in item.find('Properties') if p.get('name') == name)
def vector(item, name):
    p = property_node(item, name)
    return tuple(float(p.find(axis).text) for axis in ('X', 'Y', 'Z'))
ground_size = vector(ground, 'size')
ground_pos = vector(ground, 'CFrame')
spawn_pos = vector(spawn, 'CFrame')
assert ground_size == (240, 1, 240)
assert abs(spawn_pos[0] - ground_pos[0]) < ground_size[0] / 2
assert abs(spawn_pos[2] - ground_pos[2]) < ground_size[2] / 2
assert spawn_pos[1] > ground_pos[1] + ground_size[1] / 2
assert property_node(spawn, 'Enabled').text == 'true'
assert property_node(spawn, 'Duration').tag == 'int', 'Spawn Duration must serialize as Int32'
for part in parts:
    assert property_node(part, 'CanCollide').text == 'true'
    assert all(d > 0 for d in vector(part, 'size'))
binary = Path('build/RecordLabel.rbxl').read_bytes()
assert binary.startswith(b'<roblox!'), 'Binary place missing or malformed'
assert len(binary) > 10000, 'Binary place unexpectedly empty'
bootstrap = Path('src/server/World.server.lua').read_text()
assert 'GetDataStore' not in bootstrap and 'require(' not in bootstrap
assert 'local definitions = {' in bootstrap and '__PART_DEFINITIONS__' not in bootstrap
assert Path('build/RestoreTown.lua').read_text() == bootstrap
assert any(i.get('class') == 'SpawnLocation' for i in parts)
prompts = [i for i in children if i.get('class') == 'ProximityPrompt']
assert len(prompts) == 4, 'Discovery/studio prompts missing'
for location in ('Your Studio', 'Open Mic', 'Park Stage', 'Music Cafe'):
    assert any(name(i) == location + ' booth' for i in parts), location
for path in Path('src').rglob('*.lua'):
    expected = path.read_text()
    assert any(any(p.get('name') == 'Source' and p.text == expected for p in i.find('Properties')) for i in items), path
print(f'Place regression checks passed: {len(parts)} anchored parts, spawn, 4 prompts, and current script sources embedded before Play')
