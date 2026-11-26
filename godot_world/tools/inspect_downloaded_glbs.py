#!/usr/bin/env python3
"""Inspect downloaded GLB candidates; never auto-approve visuals."""
from pathlib import Path
import json,struct,sys
root=Path(__file__).resolve().parents[1]
receipt=root/'assets'/'asset_download_receipt.json'
items=json.loads(receipt.read_text())
out=[]
for record in items:
 p=root.parent/record['path'] if False else (root/record['path'].replace('assets/','',1))
 # receipt paths relative to Godot project root (godot_world/)
 p=root/record['path'].replace('assets/','assets/',1)
 data=p.read_bytes()
 if len(data)<20: raise SystemExit(f'TRUNCATED: {p}')
 magic,version,total=struct.unpack_from('<4sII',data)
 if magic!=b'glTF' or version!=2 or total!=len(data): raise SystemExit(f'BAD GLB HEADER: {p}')
 offset=12; doc=None
 while offset+8<=len(data):
  n,kind=struct.unpack_from('<II',data,offset);offset+=8
  chunk=data[offset:offset+n];offset+=n
  if kind==0x4E4F534A:doc=json.loads(chunk.decode('utf-8').rstrip(' \t\r\n\0'));break
 if doc is None: raise SystemExit(f'MISSING JSON CHUNK: {p}')
 item={'path':record['path'],'bytes':len(data),'meshes':len(doc.get('meshes',[])),'nodes':len(doc.get('nodes',[])),'skins':len(doc.get('skins',[])),'animations':len(doc.get('animations',[])),'materials':len(doc.get('materials',[])),'textures':len(doc.get('textures',[]))}
 if record['category']=='character' and not item['skins']: item['structural_warning']='character candidate has no skin/rig'
 print(json.dumps(item));out.append(item)
(root/'assets'/'asset_structural_report.json').write_text(json.dumps(out,indent=2))
print('Inspection complete. This is structural evidence only, not visual approval.')
