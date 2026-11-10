"""Refine ninja mouth wrap and witch hat; keep unrelated wearables intact."""
import bpy,math,runpy,json
from pathlib import Path
from mathutils import Vector
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
H=runpy.run_path(str(BASE/"build_helmet_tiers.py"))
G=H["mesh"].__globals__
mesh=H["mesh"];tube=H["tube"];line=H["line"];crystal=H["crystal"];material=H["material"]
def context(id,scene):
    global root,coll
    bpy.context.window.scene=bpy.data.scenes[scene]
    root=bpy.data.objects["wear_"+id];coll=bpy.data.collections["VEST_"+id]
    G.update(root=root,coll=coll,tag=id)
def archive(objects,id):
    # Keep a full rollback copy in a separate, unlinked collection.
    ac=bpy.data.collections.new("ARCHIVE_"+id+"_v01")
    ac.use_fake_user=True
    for ob in objects:
        matrix=ob.matrix_world.copy()
        for old in list(ob.users_collection):old.objects.unlink(ob)
        ac.objects.link(ob);ob.parent=None;ob.matrix_world=matrix
        ob.name="OLD_"+ob.name
def finish_smooth(ob):
    for p in ob.data.polygons:p.use_smooth=True
    return ob
def ninja():
    context("ninja","Armaduras - 01 Frio e calor")
    archive([o for o in list(root.children) if "Mascara de tecido" in o.name or "Ponto da costura" in o.name],"ninja_mask")
    cloth=material("Ninja pano envolvente","242C3C",0,.90)
    hem=material("Ninja bainha suave","343E50",0,.88)
    # Cross-face fabric: raised bridge at the middle, open around both eyes,
    # then rolls over the rounded lower face into the neck garment.
    NX=49;NY=17;vs=[];fs=[]
    def point(u,t):
        x=1.91*u
        # Side ends reach back to the hood; centre bridge sits between eyes.
        ytop=1.13-.17*math.exp(-(x/.30)**2)-.63*abs(u)**8
        yfront=1.99-.62*abs(u)**4
        y=ytop+(yfront-ytop)*math.sin(t*math.pi/2)
        z=1.24-.56*t**1.7+.06*(1-u*u)*math.sin(math.pi*t)
        z+=.026*math.sin(3.4*math.pi*t+.5*u)*math.sin(math.pi*t)
        return (x,y,z)
    for i in range(NX):
        u=-1+2*i/(NX-1)
        for j in range(NY):vs.append(point(u,j/(NY-1)))
    for i in range(NX-1):
        for j in range(NY-1):
            a=i*NY+j;fs.append((a,a+NY,a+NY+1,a+1))
    ob=finish_smooth(mesh("Mascara de pano v02",vs,fs,cloth))
    solid=ob.modifiers.new("Espessura do pano","SOLIDIFY");solid.thickness=.065;solid.offset=-1
    bevel=ob.modifiers.new("Acabamento macio","BEVEL");bevel.width=.018;bevel.segments=2
    line("Costura superior da mascara",[(x,y-.006,z+.008) for x,y,z in [point(-1+2*i/48,0) for i in range(49)]],.022,hem)
    # Two broad soft folded cloth strips, almost flush with the main surface.
    for k,t0 in enumerate((.41,.72)):
        fvs=[];ffs=[]
        for i in range(41):
            u=-1+2*i/40
            for off in (-.032,.032):
                x,y,z=point(u,t0+.025*u+off)
                fvs.append((x,y+.006,z+.014*math.sin(math.pi*i/40)))
        for i in range(40):ffs.append((2*i,2*i+2,2*i+3,2*i+1))
        fold=finish_smooth(mesh("Dobra discreta "+str(k),fvs,ffs,hem))
        sol=fold.modifiers.new("Borda de tecido","SOLIDIFY");sol.thickness=.012
    # The cloth wraps around the cheeks into the existing hood, no flat plate.
    for s in (-1,1):
        pts=[(s*1.87,.53,1.24),(s*1.95,.10,1.22),(s*1.97,-.23,1.24)]
        tube("Encaixe lateral da mascara "+str(s),pts,[.10,.10,.08],cloth,12)
    root["design"]="Capuz ninja com mascara de pano envolvente, ponte central e duas dobras suaves."
    root["revision"]="v02 mouth wrap"
def witch():
    context("witch","Armaduras - 02 Especiais")
    archive(list(root.children),"witch_hat")
    purple=material("Bruxa tecido ameixa","554074",0,.84)
    side=material("Bruxa painel violeta","634B86",0,.82)
    brim_mat=material("Bruxa aba violeta escura","382A4D",0,.88)
    edge=material("Bruxa bainha","251D35",0,.88)
    leather=material("Bruxa faixa vinho","754048",0,.72)
    gold=material("Bruxa latão","C6A05E",.50,.4)
    green=material("Bruxa esmeralda","4FA486",.25,.28)
    # Flexible oval brim: no straight square corners, raised flanks and
    # shallow waves. Front boundary remains behind the player's eye discs.
    N=80;R=6;vs=[];fs=[]
    def rim(a,t):
        ix=1.45*math.cos(a);iy=-1.02+.79*math.sin(a)
        ox=2.55*math.cos(a)
        oy=min(-1.28+1.43*math.sin(a),-.12-.06*math.cos(a)**2)
        x=ix+(ox-ix)*t;y=iy+(oy-iy)*t
        z=1.49+t*(.13*math.cos(2*a)+.09*math.sin(3*a+.5))+.055*t*t
        return (x,y,z)
    for j in range(R):
        for i in range(N):vs.append(rim(2*math.pi*i/N,j/(R-1)))
    for j in range(R-1):
        for i in range(N):n=(i+1)%N;fs.append((j*N+i,j*N+n,(j+1)*N+n,(j+1)*N+i))
    ob=finish_smooth(mesh("Aba oval ondulada v02",vs,fs,brim_mat))
    sol=ob.modifiers.new("Tecido espesso","SOLIDIFY");sol.thickness=.095;sol.offset=-1
    line("Acabamento da aba",[rim(2*math.pi*i/N,1) for i in range(N+1)],.033,edge)
    # Horizontal elliptical rings avoid the old tube's tilted base and
    # smoothly taper into a long sideways curl.
    rings=[(0,-1.02,1.48,1.46,.80),(0,-1.03,1.68,1.38,.76),
      (0,-1.06,1.96,1.20,.67),(.01,-1.10,2.30,.98,.57),
      (.06,-1.14,2.65,.77,.47),(.16,-1.17,2.98,.59,.37),
      (.33,-1.18,3.28,.44,.29),(.57,-1.17,3.52,.32,.22),
      (.84,-1.13,3.66,.24,.17),(1.13,-1.06,3.70,.17,.12),
      (1.39,-.96,3.61,.11,.085),(1.60,-.86,3.44,.015,.018)]
    n=48;vs=[];fs=[]
    for x,y,z,rx,ry in rings:
        for i in range(n):
            a=2*math.pi*i/n
            wave=.018*math.cos(5*a)*min(1,rx)
            vs.append((x+(rx+wave)*math.cos(a),y+(ry+wave*.55)*math.sin(a),z))
    for j in range(len(rings)-1):
        for i in range(n):k=(i+1)%n;fs.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
    fs+=[tuple(range(n))[::-1],tuple(range((len(rings)-1)*n,len(rings)*n))]
    crown=finish_smooth(mesh("Copa curva de tecido v02",vs,fs,purple))
    crown.data.materials.append(side)
    for j,poly in enumerate(crown.data.polygons):
        if (j%n)//8 in (1,4):poly.material_index=1
    # Wine-colored band hugs the lower cone, with a buckle at the front.
    bvs=[];bfs=[]
    for x,y,z,rx,ry in [(0,-1.03,1.63,1.415,.79),(0,-1.06,1.94,1.23,.70)]:
        for i in range(n):
            a=2*math.pi*i/n;bvs.append((x+rx*math.cos(a),y+ry*math.sin(a),z))
    for i in range(n):k=(i+1)%n;bfs.append((i,k,n+k,n+i))
    band=finish_smooth(mesh("Faixa vinho ajustada",bvs,bfs,leather))
    so=band.modifiers.new("Couro da faixa","SOLIDIFY");so.thickness=.055
    def buckle(x,z):
        t=(z-1.63)/.31;rx=1.415+(1.23-1.415)*t;ry=.79+(.70-.79)*t;cy=-1.03-.03*t
        return (x,cy+ry*math.sqrt(1-(x/rx)**2)+.045,z)
    pts=[buckle(-.28,1.68),buckle(.28,1.68),buckle(.28,1.89),buckle(-.28,1.89),buckle(-.28,1.68)]
    line("Fivela dourada vazada",pts,.042,gold)
    line("Pino da fivela",[buckle(0,1.68),buckle(0,1.89)],.025,gold)
    # Small sewn patch and fine seam on the side, rather than floating stars.
    # A tiny gem attached to the buckle adds a readable fantasy detail.
    gemcenter=Vector(buckle(.0,1.79))
    crystal("Gema presa na faixa",tuple(gemcenter),tuple(gemcenter+Vector((0,.13,.07))),.085,green,None,5)
    seam=[]
    a=2.70
    for x,y,z,rx,ry in rings[:8]:seam.append((x+rx*math.cos(a)*1.008,y+ry*math.sin(a)*1.008,z))
    line("Costura lateral da copa",seam,.014,edge)
    root["design"]="Chapeu de bruxa de aba oval ondulada, copa alta com ponta curva e faixa vinho com fivela vazada."
    root["revision"]="v02 fluid brim and crown"
if __name__=="__main__":
    ninja();witch();bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))
    print("Ninja mask and witch hat updated, other models preserved.")

