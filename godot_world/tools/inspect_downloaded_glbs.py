#!/usr/bin/env python3
"""Structural inspection of staged GLB assets; not visual QA."""
from pathlib import Path
import json, struct
root=Path(__file__).resolve().parents[1]
receipt=root/'assets'/'asset_download_receipt.json'
items=json.loads(receipt.read_text(encoding='utf-8'))
out=[]
for record in items:
 p=root/record['path']
 data=p.read_bytes()
 if len(data)<20: raise SystemExit(f'TRUNCATED: {p}')
 magic,version,total=struct.unpack_from('<4sII',data)
 if magic!=b'glTF' or version!=2 or total!=len(data): raise SystemExit(f'BAD GLB HEADER: {p}')
 offset=12; doc=None
 while offset+8<=len(data):
  n,kind=struct.unpack_from('<II',data,offset);offset+=8
  chunk=data[offset:offset+n];offset+=n
  if offset>len(data):raise SystemExit(f'CHUNK OVERFLOW: {p}')
  if kind==0x4E4F534A:
   doc=json.loads(chunk.decode('utf-8').rstrip(' \\t\\r\\n\\0'));break
 if doc is None:raise SystemExit(f'MISSING JSON CHUNK: {p}')
 item={'category':record['category'],'path':record['path'],'bytes':len(data),'meshes':len(doc.get('meshes',[])),'nodes':len(doc.get('nodes',[])),'skins':len(doc.get('skins',[])),'animations':len(doc.get('animations',[])),'materials':len(doc.get('materials',[])),'textures':len(doc.get('textures',[]))}
 if record['category']=='character' and not item['skins']:item['structural_warning']='character candidate has no skin/rig'
 out.append(item)
 print(json.dumps(item))
(root/'assets'/'asset_structural_report.json').write_text(json.dumps(out,indent=2)+'\\n',encoding='utf-8')
print('Inspection complete: structural validation only, not visual approval.')
