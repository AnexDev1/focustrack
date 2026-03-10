from PIL import Image, ImageDraw
import os
os.makedirs('assets', exist_ok=True)
img = Image.new('RGBA', (256,256), (0,0,0,0))
draw = ImageDraw.Draw(img)
colors = [(99,102,241,255), (255,255,255,255), (99,102,241,255), (255,255,255,255)]
radii = [120,80,40,16]
for r,c in zip(radii, colors):
    draw.ellipse((128-r,128-r,128+r,128+r), fill=c)
img.save('assets/target.png')
print('created assets/target.png')
