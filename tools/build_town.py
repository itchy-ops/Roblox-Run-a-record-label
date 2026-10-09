"""Create an editable Roblox town model, included in the place before scripts run."""
from pathlib import Path
import xml.etree.ElementTree as ET

root = ET.Element('roblox', version='4')
serial = 0

def item(parent, kind, name):
    global serial
    serial += 1
    obj = ET.SubElement(parent, 'Item', {'class': kind, 'referent': f'RBX{serial}'})
    props = ET.SubElement(obj, 'Properties')
    prop(props, 'string', 'Name', name)
    return obj, props

def prop(props, kind, name, value):
    node = ET.SubElement(props, kind, name=name)
    if isinstance(value, dict):
        for k, v in value.items():
            ET.SubElement(node, k).text = str(v)
    else:
        node.text = str(value).lower() if isinstance(value, bool) else str(value)
    return node

def vec(values):
    return dict(zip(('X', 'Y', 'Z'), values))

def color(values):
    return dict(zip(('R', 'G', 'B'), (v / 255 for v in values)))

town, _ = item(root, 'Model', 'Town')

def part(name, size, position, rgb, kind='Part'):
    obj, p = item(town, kind, name)
    prop(p, 'bool', 'Anchored', True)
    prop(p, 'bool', 'CanCollide', True)
    prop(p, 'Vector3', 'Size', vec(size))
    cf = vec(position)
    cf.update({f'R{i}{j}': int(i == j) for i in range(3) for j in range(3)})
    prop(p, 'CoordinateFrame', 'CFrame', cf)
    prop(p, 'Color3', 'Color', color(rgb))
    prop(p, 'token', 'TopSurface', 0)
    prop(p, 'token', 'BottomSurface', 0)
    return obj, p

part('Town Ground', (240, 1, 240), (0, -1, 0), (63, 91, 77))
part('Main Street', (22, .2, 200), (0, -.35, 0), (42, 44, 54))
_, spawn = part('Town Spawn', (8, 1, 8), (0, 1, 65), (112, 82, 213), 'SpawnLocation')
prop(spawn, 'bool', 'Neutral', True)
prop(spawn, 'float', 'Duration', 0)
locations = [('Your Studio', -40, 45), ('Open Mic', 40, 25), ('Park Stage', -40, -25), ('Music Cafe', 40, -55)]
for index, (name, x, z) in enumerate(locations, 1):
    floor, _ = part(name, (30, 1, 26), (x, 0, z), (65 + index * 20, 62, 94))
    part(name + ' rear wall', (30, 12, 1), (x, 6, z - 13), (44, 49, 65))
    for side in (-15, 15):
        part(name + (' left wall' if side < 0 else ' right wall'), (1, 12, 26), (x + side, 6, z), (44, 49, 65))
    # Sidewalks lead from the road to the open front of each location.
    part(name + ' path', (18, .2, 8), ((-20 if x < 0 else 20), -.25, z + 8), (140, 143, 151))
    sign, p = item(floor, 'BillboardGui', 'Location Sign')
    prop(p, 'UDim2', 'Size', {'XS': 0, 'XO': 220, 'YS': 0, 'YO': 50})
    prop(p, 'Vector3', 'StudsOffset', vec((0, 13, 0)))
    prop(p, 'bool', 'AlwaysOnTop', True)
    _, p = item(sign, 'TextLabel', 'Title')
    prop(p, 'UDim2', 'Size', {'XS': 1, 'XO': 0, 'YS': 1, 'YO': 0})
    prop(p, 'float', 'BackgroundTransparency', 1)
    prop(p, 'string', 'Text', name)
    prop(p, 'Color3', 'TextColor3', color((255, 255, 255)))
    prop(p, 'bool', 'TextScaled', True)
    booth, _ = part(name + ' booth', (5, 3, 3), (x, 2, z - 7), (117, 82, 165))
    _, p = item(booth, 'ProximityPrompt', 'ProximityPrompt')
    prop(p, 'string', 'ActionText', 'Check studio' if index == 1 else 'Discover local talent')
    prop(p, 'string', 'ObjectText', name)
    prop(p, 'float', 'MaxActivationDistance', 10)
    if index == 1:
        part('Battered mixing desk', (8, 2, 4), (x - 7, 2, z + 3), (75, 65, 57))
        part('Old microphone', (.4, 5, .4), (x + 7, 3, z), (105, 105, 105))
    else:
        part(name + ' stage', (12, 1, 6), (x, 1, z - 4), (94, 82, 115))

path = Path(__file__).resolve().parents[1] / 'assets' / 'Town.rbxmx'
ET.indent(root)
ET.ElementTree(root).write(path, encoding='utf-8', xml_declaration=True)
print(f'Built editable town model ({serial} instances)')
