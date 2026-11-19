"""Compõe os banners e a prova animada usando os mesmos pontos da UI em BundleBanner."""
import json
from math import pi, sin
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
PACOTES = ROOT.parents[2] / "skins/roblox/primeira_leva/pacotes.json"
DATA = [(p["id"], p["nome"], p["raridade"], list(p["itens"].values()))
        for p in json.loads(PACOTES.read_text(encoding="utf8"))]
ROLES = ["personagem", "caixa", "mochila", "livro"]
SIZES = [190, 116, 115, 112]
CENTERS = [92, 228, 329, 432]


def font(size):
    return ImageFont.truetype("C:/Windows/Fonts/ARLRDBD.TTF", size)


def draw_frame(slug, title, rarity, labels, images, t, w=1120, h=300, text=True, fx=True):
    scale = min(h/300, (w*.56-66)/490)
    wave = sin(t*pi/3)
    bg = ImageOps.fit(images["fundo"], (round(w*1.025),round(h*1.025)))
    x = round((bg.width-w)/2-w*.006*wave)
    y = (bg.height-h)//2
    canvas = bg.crop((x,y,x+w,y+h))
    leaves, sea = slug == "bosque_desperto", slug == "mare_profunda"
    for i in range(3 if leaves else 1):
        phase = (t/3 - i/3) % 1
        side = round(h * (.09+.05*phase if leaves else .32 if sea else .24))
        px, py = ((.57+.05*sin(phase*pi*2), .12+.52*phase) if leaves else (.58, .51 if sea else .42))
        angle = 100*phase if leaves else t*60 if sea else 14*wave
        opacity = .70*sin(phase*pi) if leaves else .5 if sea else .76
        sprite = images["ambiente"].resize((side,side),Image.Resampling.LANCZOS)
        sprite = sprite.rotate(-angle,Image.Resampling.BICUBIC,expand=True)
        sprite.putalpha(sprite.getchannel("A").point(lambda a:round(a*opacity)))
        canvas.alpha_composite(sprite,(round(px*w-sprite.width/2),round(py*h-sprite.height/2)))
    for i,key in enumerate(ROLES):
        side = max(1, round(SIZES[i]*scale))
        tile = images[key].resize((side,side),Image.Resampling.LANCZOS)
        if i == 0:
            tile = tile.rotate(-1.5*wave,Image.Resampling.BICUBIC)
        canvas.alpha_composite(tile,(round(66+CENTERS[i]*scale-side/2),round(h*.64-side+(-3*wave*scale if i==0 else 0))))
    effect = Image.new("RGBA",canvas.size)
    for i in range(1,4):
        route = slug=="norte_perdido"
        phase=(t/2.1-(i-1)*.16)%1
        dx=(i-2)*8
        if route:
            cx,cy = 66+(CENTERS[3]-16+dx)*scale,h*.64-(36+(i-1)*5)*scale
            opacity=min(1,max(0,(t%6-1.3-(i-1)*.17)*8))*min(1,max(0,(3.4-t%6)*3))
        else:
            cx,cy = 66+(CENTERS[2]+dx+5*sin(phase*pi))*scale,h*.64-(94+48*phase)*scale
            opacity=sin(phase*pi)
        side=max(1,round((11 if route else 13+3*i)*scale))
        spark=images["particula"].resize((side,side),Image.Resampling.LANCZOS)
        spark.putalpha(spark.getchannel("A").point(lambda a:round(a*opacity)))
        effect.alpha_composite(spark,(round(cx-side/2),round(cy-side/2)))
    if fx:
        canvas.alpha_composite(effect)
    if text:
        d=ImageDraw.Draw(canvas)
        def label(xy,word,size,anchor):
            d.text(xy,word,font=font(size),anchor=anchor,fill="#fff2d1",stroke_width=2,stroke_fill="#35231c")
        label((66,h*.75),title.upper(),round(h*.135),"lm")
        size=round(h*.058)
        d.rounded_rectangle((66,h*.85,90+d.textlength(rarity,font=font(size)),h*.95),radius=5,
                            fill={"Épico":"#8743B1", "Lendário":"#A4650B", "Mítico":"#C03939"}[rarity],outline="#3b2620",width=2)
        label((78,h*.9),rarity,size,"lm")
        for i,name in enumerate(labels):
            label((w-66,h*(.28+.11*i)),name,round(h*.073),"rm")
    return canvas.convert("RGB"),effect


if __name__ == "__main__":
    frames=[]
    sheet=Image.new("RGB",(840,675))
    compare=Image.new("RGB",(960,504),"#241c20")
    for index,(slug,title,rarity,labels) in enumerate(DATA):
        folder=ROOT/slug
        # Um véu escuro na metade direita dá contraste ao preço e aos textos vivos.
        bg=ImageOps.fit(Image.open(folder/"cenario-cartoon.png").convert("RGBA"),(1120,300),method=Image.Resampling.LANCZOS)
        veil=Image.new("RGBA",bg.size)
        ink=ImageDraw.Draw(veil)
        for x in range(bg.width):
            ink.line((x,0,x,299),fill=(26,15,38,round(13+100*min(1,max(0,(x-500)/520)))))
        bg.alpha_composite(veil)
        bg.convert("RGB").save(folder/"fundo.png")
        imgs={"fundo":bg, **{n: Image.open(folder/(n+".png")).convert("RGBA") for n in ("particula","ambiente")}}
        for key in ROLES:
            item=Image.open(folder/(key+".png")).convert("RGBA")
            a=item.getchannel("A")
            sticker=Image.new("RGBA",item.size,(54,27,40,0))
            sticker.putalpha(a.filter(ImageFilter.MaxFilter(13)))
            sticker.alpha_composite(item)
            sticker.save(folder/("loja-"+key+".png"))
            imgs[key]=sticker
        args=(slug,title,rarity,labels,imgs)
        poster,_=draw_frame(*args,0,text=False,fx=False)
        poster.save(folder/"previa.png")
        still,effect=draw_frame(*args,2)
        effect.save(folder/"efeito.png")
        sheet.paste(still.resize((840,225),Image.Resampling.LANCZOS),(0,index*225))
        compact,_=draw_frame(*args,2,640,180)
        compare.paste(still.resize((590,158),Image.Resampling.LANCZOS),(0,index*168))
        compare.paste(compact.resize((360,101),Image.Resampling.LANCZOS),(600,index*168+28))
        for frame in range(72):
            im,_=draw_frame(*args,frame/12)
            frames.append(im)
    frames[0].save(ROOT/"previa-carrossel.webp",save_all=True,append_images=frames[1:],
                   duration=[round((i+1)*1000/12)-round(i*1000/12) for i in range(len(frames))],
                   loop=0,quality=88,method=3)
    sheet.save(ROOT/"previa-tres-bundles.png")
    compare.save(ROOT/"comparacao-layout.jpg",quality=94)
