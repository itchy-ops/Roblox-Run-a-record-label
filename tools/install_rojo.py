"""Install a pinned Rojo release and verify GitHub's published SHA-256 digest."""
import hashlib
import io
import os
from pathlib import Path
import urllib.request
import zipfile

VERSION = '7.6.1'
root = Path(__file__).resolve().parents[1]
target = root / '.tools' / 'rojo'
digest = 'sha256:a9542a713036897fdbd0173e7a105ea409658333133c949025fcb6f1a7ca909d'
# Published on https://github.com/rojo-rbx/rojo/releases/expanded_assets/v7.6.1
asset = {'browser_download_url': f'https://github.com/rojo-rbx/rojo/releases/download/v{VERSION}/rojo-{VERSION}-linux-x86_64.zip'}
with urllib.request.urlopen(asset['browser_download_url'], timeout=60) as response:
    data = response.read()
if hashlib.sha256(data).hexdigest() != digest.split(':', 1)[1]:
    raise RuntimeError('Rojo release checksum mismatch')
with zipfile.ZipFile(io.BytesIO(data)) as archive:
    executable = archive.read('rojo')
target.parent.mkdir(exist_ok=True)
target.write_bytes(executable)
os.chmod(target, 0o755)
print(f'Installed verified Rojo {VERSION}')
