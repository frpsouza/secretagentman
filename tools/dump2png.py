import sys,zlib,struct,os
PAL=[(0,0,0),(29,43,83),(126,37,83),(0,135,81),(171,82,54),(95,87,79),(194,195,199),(255,241,232),(255,0,77),(255,163,0),(255,236,39),(0,228,54),(41,173,255),(131,118,156),(255,119,168),(255,204,170)]
def png(path,rows,scale=3):
    h=len(rows);w=len(rows[0])
    raw=b''
    for r in rows:
        line=b''.join(bytes(PAL[int(c,16)])*scale for c in r)
        raw+=(b'\x00'+line)*scale
    def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    open(path,'wb').write(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',w*scale,h*scale,8,2,0,0,0))+ch(b'IDAT',zlib.compress(raw))+ch(b'IEND',b''))
src,out=sys.argv[1],sys.argv[2]
lines=[l.rstrip('\n') for l in open(src,encoding='utf-8',errors='ignore')]
lines=[l[6:] if l.startswith('INFO: ') else l for l in lines]
i=0
while i<len(lines):
    if lines[i].startswith('@@'):
        name=lines[i][2:];rows=lines[i+1:i+129]
        if len(rows)==128 and all(len(r)==128 for r in rows): png(os.path.join(out,name+'.png'),rows)
        i+=129
    else:
        if lines[i].startswith('LOG'): print(lines[i])
        i+=1
