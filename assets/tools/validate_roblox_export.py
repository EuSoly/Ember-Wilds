"""Validate the combined FBX and all 29 individual FBXs by reimporting."""
import os
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools'
template=os.path.join(os.path.dirname(BASE),'weapons','validate_roblox_export.py')
code=open(template,encoding='utf8').read()
code=code.replace('weapons','tools').replace('==18','==29').replace('"meshes":18','"meshes":29')
code=code.replace('espadas-e-lancas','picaretas-e-ferramentas')
exec(compile(code,'tools_validation_pipeline','exec'))
