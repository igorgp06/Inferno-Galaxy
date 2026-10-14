from PIL import Image, ImageDraw
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets'/'sprites'
ROOT.mkdir(parents=True,exist_ok=True)
INK='#10132a'
SHADE='#242b50'
WHITE='#eefbff'

def make(name, size, draw_fn):
    img=Image.new('RGBA',size,(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_fn(d)
    img.save(ROOT/name)

def ship(d,thrust=False):
    # Outline pixelada de uma nave simetrica vista de cima.
    d.polygon([(15,0),(19,0),(21,5),(24,7),(25,13),(31,19),(31,27),(25,27),(21,24),(20,30),(12,30),(11,24),(7,27),(1,27),(1,19),(7,13),(8,7),(11,5),(12,1)],fill=INK)
    d.polygon([(15,2),(17,2),(19,8),(20,19),(17,25),(15,25),(12,19),(13,8)],fill='#24bdda')
    d.polygon([(7,15),(12,11),(12,21),(8,24),(3,24),(3,20)],fill='#11759f')
    d.polygon([(25,15),(20,11),(20,21),(24,24),(29,24),(29,20)],fill='#11759f')
    d.rectangle((14,4,17,12),fill='#74f6ff')
    d.rectangle((14,5,17,9),fill=WHITE)
    d.rectangle((12,17,19,20),fill='#26629e')
    d.rectangle((14,13,17,15),fill=WHITE)
    d.rectangle((4,22,7,23),fill='#70faff')
    d.rectangle((24,22,27,23),fill='#70faff')
    # Motores em dois frames.
    d.rectangle((10,27,13,29),fill='#ffb764')
    d.rectangle((19,27,22,29),fill='#ffb764')
    if thrust:
        d.polygon([(10,29),(10,31),(11,31),(11,33),(12,33),(13,29)],fill='#ff7c42')
        d.polygon([(19,29),(19,33),(20,33),(20,31),(22,31),(22,29)],fill='#ff7c42')
        d.rectangle((11,28,12,30),fill='#fff5ba')
        d.rectangle((20,28,21,30),fill='#fff5ba')

make('player_idle.png',(34,36),lambda d:ship(d,False))
make('player_thrust.png',(34,36),lambda d:ship(d,True))

def enemy0(d):
    d.polygon([(0,2),(9,6),(13,3),(18,3),(22,6),(31,2),(29,18),(23,24),(18,20),(15,26),(12,20),(6,24),(1,18)],fill=INK)
    d.polygon([(3,7),(10,10),(13,6),(18,6),(21,10),(28,7),(26,16),(21,21),(17,17),(14,17),(10,21),(5,16)],fill='#d43c68')
    d.polygon([(9,10),(15,8),(21,10),(19,16),(12,16)],fill='#ff6b72')
    d.rectangle((13,10,18,13),fill='#fff2c0')
    d.rectangle((4,15,7,17),fill='#ff9e6f'); d.rectangle((24,15,27,17),fill='#ff9e6f')

def enemy1(d):
    d.polygon([(0,13),(7,4),(14,7),(17,7),(24,4),(31,13),(28,26),(19,21),(16,26),(13,21),(3,26)],fill=INK)
    d.polygon([(3,13),(9,7),(14,11),(17,11),(23,7),(28,13),(26,23),(19,17),(16,22),(13,17),(5,23)],fill='#d27a33')
    d.polygon([(12,12),(16,8),(20,12),(20,17),(12,17)],fill='#ffd274')
    d.rectangle((14,12,17,15),fill=WHITE)
    d.rectangle((5,17,10,19),fill='#f7b15d'); d.rectangle((22,17,27,19),fill='#f7b15d')

def enemy2(d):
    d.polygon([(0,7),(8,0),(13,6),(18,6),(23,0),(31,7),(26,15),(28,29),(20,23),(16,27),(11,23),(3,29),(5,15)],fill=INK)
    d.polygon([(3,8),(8,4),(13,10),(18,10),(23,4),(28,8),(23,15),(25,24),(19,19),(16,23),(12,19),(6,24),(8,15)],fill='#745fd4')
    d.polygon([(12,11),(16,8),(20,11),(22,17),(16,21),(10,17)],fill='#b895ff')
    d.rectangle((13,13,19,16),fill='#e9deff')
    d.rectangle((5,7,9,9),fill='#cb95fb');d.rectangle((23,7,27,9),fill='#cb95fb')

for i,fn in enumerate([enemy0,enemy1,enemy2]):make(f'enemy_{i}.png',(32,32),fn)

def boss(d):
    # Silhueta escalonada e armadura multicamada.
    d.polygon([(1,23),(10,10),(24,12),(32,4),(36,1),(43,1),(47,4),(55,12),(69,10),(78,23),(77,44),(64,43),(53,36),(43,46),(36,46),(26,36),(15,43),(2,44)],fill=INK)
    d.polygon([(5,24),(13,14),(25,16),(34,7),(37,5),(42,5),(45,7),(54,16),(66,14),(74,24),(73,40),(63,39),(53,32),(43,42),(36,42),(27,32),(16,39),(6,40)],fill='#ac3d75')
    d.polygon([(12,23),(27,20),(33,13),(46,13),(52,20),(67,23),(53,29),(45,25),(40,35),(34,25),(26,29)],fill='#e4629d')
    d.polygon([(18,30),(27,24),(27,33),(17,37),(10,37),(10,32)],fill='#6353bb')
    d.polygon([(62,30),(53,24),(53,33),(63,37),(70,37),(70,32)],fill='#6353bb')
    d.polygon([(30,14),(36,8),(43,8),(50,14),(47,25),(32,25)],fill='#322f62')
    d.polygon([(36,14),(40,10),(44,14),(44,20),(36,20)],fill='#ffd9ef')
    d.rectangle((37,14,43,17),fill='#ffffff')
    d.rectangle((12,24,20,27),fill='#ffb5bc');d.rectangle((60,24,68,27),fill='#ffb5bc')
    d.rectangle((23,34,30,40),fill='#3d2d81');d.rectangle((50,34,57,40),fill='#3d2d81')
    d.rectangle((24,39,28,45),fill='#ff8256');d.rectangle((51,39,55,45),fill='#ff8256')
    d.rectangle((25,42,27,48),fill='#ffd37e');d.rectangle((52,42,54,48),fill='#ffd37e')
    for x in (8,69):d.rectangle((x,24,x+3,33),fill='#502f80')
make('boss_guardian.png',(80,50),boss)

def pickup(d,c1,c2,char):
    d.polygon([(12,0),(21,8),(21,16),(12,24),(3,16),(3,8)],fill=INK)
    d.polygon([(12,2),(19,9),(19,15),(12,22),(5,15),(5,9)],fill=c1)
    d.polygon([(12,4),(17,9),(17,15),(12,20),(7,15),(7,9)],fill=c2)
    font={'R':['111','101','111','110','101'], 'D':['110','101','101','101','110']}
    for yy,line in enumerate(font[char]):
        for xx,val in enumerate(line):
            if val=='1':d.point((10+xx,9+yy),fill=INK)
make('boost_rapid.png',(24,24),lambda d:pickup(d,'#16a992','#8effd8','R'))
make('boost_double.png',(24,24),lambda d:pickup(d,'#e8a543','#ffe58b','D'))
print('Gerados:',*[p.name for p in sorted(ROOT.iterdir())])
