-- draw: title, building, entities, lights out, hud

function drtitle()
 if t<40 then
  for i=0,4 do circfill(t*4-10-i*26,62,4,7) end
 else
  local r=min(32,4+(t-40)*2)
  circfill(64,62,r+2,5) circfill(64,62,r,6) circfill(64,62,r-6,7)
  for i=0,9 do
   local a=i/10+t/400
   line(64+cos(a)*(r-6),62+sin(a)*(r-6),64+cos(a+.05)*r,62+sin(a+.05)*r,5)
  end
  if t>56 then
   local f=t<96 and 1+t\5%2 or 15
   local x=t<96 and 26+(t-56)*.55 or 48
   sspr(f%8*16,f\8*24,16,24,x,38,32,48)
   if (t>=112 and t<118) circfill(77,47,(t-110)*2,10) circfill(77,47,t-110,7)
   if (t==112) sfx(0)
  end
 end
 -- blood runs down the screen after the shot
 if t>=118 then
  for x=0,127 do line(x,-1,x,(t-118)*2.5-14+sin(x/41)*6+sin(x/17)*4+x*7%5,8) end
 end
 print("\^w\^tsecret agent",17,5,0)
 print("\^w\^tsecret agent",16,4,7)
 print("\^w\^tman",53,17,0)
 print("\^w\^tman",52,16,t>=118 and 7 or 8)
 if (stt>0 and t%4<2 or stt==0 and t%30<20) cprint("push button to start",102,7)
 cprint("hi-score "..sc(hi),112,9)
 print("z:jump x:fire\x94\x83:lift/stairs",4,122,5)
end

function drworld()
 local x0,y0=flr(cx),flr(cy)
 camera(x0,y0-8)
 rectfill(x0,y0,x0+127,y0+119,12)
 for i=0,7 do
  local x,y=(i*97+t/8)%460-50,i*57-40
  circfill(x,y,6,7) circfill(x+7,y-3,7,7) circfill(x+15,y,5,7)
 end
 for i=0,4 do
  local x,h=262+i*17,40+i*37%60
  rectfill(x,416-h,x+14,416,13)
  for wy=420-h,410,8 do pset(x+4,wy,6) pset(x+10,wy,6) end
 end
 local f0,f1=max(0,y0\32),min(nf,(y0+120)\32)
 for f=f0,f1 do drfloor(f) end
 rectfill(0,416,ww,423,6) line(0,416,ww,416,7)
 rectfill(0,424,ww,431,5)
 for x=0,ww,16 do line(x,428,x+7,428,10) end
 line(276,380,276,415,5) rectfill(272,378,280,380,5) pset(276,381,10)
 for s in all(shafts) do drcar(s) end
 for f=max(1,f0),f1 do drfront(f) end
 for q in all(smk) do circfill(q.x,q.y,q.r,q.l>16 and 6 or q.l>8 and 13 or 5) end
 drcarv()
 if chute then
  -- deflating canopy: sinks, flattens and spreads, drifting behind the agent
  local k=chute.k
  local x,h,w=chute.x-chute.d*k*.5,max(2,11-k/2.5),28+k*.5
  local yb=min(32,k*k*.06)
  if (k<16) line(x-w/2+1,yb-1,p.x-4,20,6) line(x+w/2-1,yb-1,p.x+3,20,6)
  sspr(16,48,24,8,x-w/2,yb-h,w,h)
 end
 for e in all(ens) do drent(e) end
 drent(p)
 for b in all(bul) do line(b.x,b.y,b.x-sgn(b.dx)*3,b.y,b.pl and 10 or 8) end
 for q in all(gore) do pset(q.x,q.y,q.l>12 and 8 or 2) end
 camera()
 darken()
 camera(x0,y0-8)
 for q in all(pops) do print(q.s,q.x-#q.s*2,q.y,7) end
 camera()
end

function drfloor(f)
 local y=f*32
 if f==0 then
  line(40,-6,40,31,5) line(36,8,44,8,5) line(37,2,43,2,5)
  if (t%30<15) pset(40,-7,8)
  rectfill(88,18,128,31,5) rectfill(90,20,126,22,6)
  rectfill(194,4,242,31,6) rectfill(194,4,242,7,5)
  rectfill(204,12,230,31,0)
  rectfill(0,24,7,31,6) rectfill(248,24,255,31,6)
  return
 end
 rectfill(0,y,255,y+3,6) line(0,y+3,255,y+3,5)
 rectfill(8,y+4,247,y+31,12)
 line(8,y+25,247,y+25,13)
 for x=32,224,48 do line(x,y+4,x,y+24,13) end
 rectfill(0,y+4,7,y+31,5) rectfill(248,y+4,255,y+31,5)
 print(nf-f+1,1,y+14,6)
 if f==nf then
  rectfill(248,y+8,255,y+31,got==plans and 7 or 1)
  if (got==plans and t%20<12) print("exit\x91",224,y+12,8)
 end
 for s in all(shafts) do
  if f>=s.t and f<=s.b then
   rectfill(s.x,y+(f==s.t and 4 or 0),s.x+23,y+31,0)
   line(s.x+3,y,s.x+3,y+31,1) line(s.x+20,y,s.x+20,y+31,1)
  end
 end
 for l in all(lamps) do
  if l.f==f then
   local x=l.x
   line(x,y+4,x,y+6,5)
   if l.ok then
    rectfill(x-1,y+7,x+1,y+7,6) rectfill(x-3,y+8,x+3,y+10,6)
    line(x-3,y+10,x+3,y+10,7) pset(x,y+11,10)
   else
    line(x-2,y+8,x,y+7,5) pset(x+2,y+9,5)
   end
  end
 end
 for d in all(doors) do
  if d.f==f then
   local x,fy=d.x,y+32
   rectfill(x-1,fy-23,x+12,fy-1,d.red and 2 or 13)
   rectfill(x,fy-22,x+11,fy-1,0)
   local w=flr(12*(1-d.o))
   if w>0 then
    rectfill(x,fy-22,x+w-1,fy-1,d.red and 8 or 1)
    if (w>8) pset(x+w-3,fy-11,10)
   end
  end
 end
 for c in all(escs) do
  if c.u==f-1 then
   local yy,x1=feet(c.u),c.x+c.dx*32
   for k=0,32 do
    local x=c.x+c.dx*k
    line(x,yy+k,x,yy+k+5,6) pset(x,yy+k,k%4<1 and 5 or 7)
   end
   line(c.x,yy-8,x1,yy+24,5)
   line(c.x,yy-8,c.x,yy,5) line(x1,yy+24,x1,yy+32,5)
  end
 end
end

-- the mini: body sprite plus wheels whose tread marks turn as it rolls
function drcarv()
 spr(101,carx,400,4,2)
 for wx in all{7,25} do
  local x,a=carx+wx,carx/19
  circfill(x,413,3,0) circfill(x,413,1,6)
  for i=0,2 do pset(x+cos(a+i/3)*2.4,413+sin(a+i/3)*2.4,5) end
 end
end

function drcar(s)
 local x,y=s.x,s.y
 line(x+11,s.t*32+4,x+11,y-32,5)
 rectfill(x+1,y-31,x+22,y-1,13)
 rectfill(x+1,y-31,x+22,y-28,5)
 rect(x+1,y-31,x+22,y,6)
 line(x+4,y-16,x+19,y-16,6)
end

function drfront(f)
 local y=f*32
 for s in all(shafts) do
  if f>=s.t and f<=s.b then
   if (f>s.t) rectfill(s.x,y,s.x+23,y+3,6)
   local on=s.y==feet(f)
   rectfill(s.x-1,y+4,s.x+24,y+8,5)
   rectfill(s.x+7,y+4,s.x+16,y+8,on and 8 or 0)
   print(nf-f+1,s.x+(f<4 and 8 or 10),y+4,on and 7 or 9)
   -- blinking arrow while a car is on its way to this floor
   if s.v~=0 and s.tg==f and t%16<10 then
    -- on the side of the panel away from the player standing at the door
    local d,ax=sgn(s.y-feet(f)),p.x<s.x+12 and s.x+20 or s.x+3
    for i=0,2 do line(ax-i,y+6-d*(1-i),ax+i,y+6-d*(1-i),10) end
   end
  end
 end
end

-- 16x24 character with a 1px navy outline below the head (the hair already
-- stands out), so black and grey legs stay readable in front of grey walls,
-- black shafts and dark doorways
function ospr(n,x,y,w,h,fl)
 -- clip works in screen space, so take the camera offset off
 clip(x-1-%0x5f28,y+9-%0x5f2a,18,16)
 for i=0,15 do pal(i,1) end
 for d in all{{-1,0},{1,0},{0,-1},{0,1}} do spr(n,x+d[1],y+d[2],w,h,fl) end
 pal() palt(0,false) palt(14,true) clip()
 spr(n,x,y,w,h,fl)
end

function drent(e)
 if (hidden(e) or e.st=="dead" and e.dt>60 and t%4<2) return
 local f,y=0,e.y-e.jy
 if e.st=="dead" then
  -- shot: agonize, staggering and clutching the wound; then thrown back
  -- (tilted mid-fall with a small hop) and lying flat in a spreading pool
  local k,sx,kf=e.dt-e.ag,e.en and 24 or 0,e.kd>0
  if e.why=="crush" then
   -- squashed between the car roof and the shaft top (or flattened by the
   -- car at the bottom): the body shrinks to the gap left and spreads out
   local h=e.rd and mid(3,y-e.sh.t*32-4,24) or max(3,24-e.dt*3)
   local w=16+(24-h)\2
   ovalfill(e.x-w/2,y-2,e.x+w/2,y,8)
   sspr(0,e.en and 24 or 0,16,24,e.x-w/2,y-h,w,h,e.dir<0)
  elseif k<0 then ospr(e.en and 156 or 154,e.x-8+(k%6<3 and 0 or e.kd),y-24,2,3,e.dir<0)
  elseif k<8 then sspr(sx,72,24,24,e.x-(kf and 8 or 16),y-24-k*(8-k)/4,24,24,kf)
  else
   local r=min(7,(k-8)/3)
   if (e.ag>0 and not e.rd) ovalfill(e.x-r-3,y-2,e.x+r+3,y+1,2) ovalfill(e.x-r,y-1,e.x+r,y,8)
   sspr(sx,64,24,8,e.x-12,y-8,24,8,not kf)
  end
  return
 end
 local s,w=e.sht,t\3%6
 if e.cr then f=s>0 and 5 or 4
 elseif e.jy>0 or e.st=="fall" or e.st=="para" then f=s>0 and 14 or 6
 -- revolver: drawn and aimed (27 -> 3), held after the shot, lowered again
 elseif e.dw then f=e.dw>7 and 27 or 3
 elseif s>16 or s>0 and not e.mv then f=s>4 and 3 or 27
 elseif e.mv then
  -- 6-frame walk cycle, body rises a pixel on the passing frames
  f=wk[w+1]
  if (w%3==2) y-=1
 end
 if (e.en) f=f==3 and 11 or f==27 and 28 or f<3 and f+8 or f>31 and f+4 or 8
 if e.st=="para" then
  -- full canopy, breathing with the wind
  local h=11+sin(t/24)*1.5
  sspr(16,48,24,8,e.x-14,y-32-h,28,h)
  line(e.x-13,y-33,e.x-4,y-20,6) line(e.x+13,y-33,e.x+3,y-20,6)
 end
 ospr(f\8*48+f%8*2,e.x-8,y-24,2,3,e.dir<0)
 drgun(e,f,y,s)
end

-- a revolver bigger than the sprite has room for: wooden grip in the hand,
-- dark cylinder, light barrel; the muzzle flash comes out of its tip
function drgun(e,f,y,s)
 local hr,hc
 if f==5 then hr,hc=20,14
 elseif f==27 or f==28 then hr,hc=12,13
 elseif f==3 or f==11 or f==14 then hr,hc=10,14
 else return end
 local d=e.dir
 local hx,hy=e.x-8+(d>0 and hc or 15-hc),y-24+hr
 pset(hx,hy+1,4) pset(hx+d,hy+1,4)
 rectfill(hx+d,hy-1,hx+2*d,hy,5)
 line(hx+3*d,hy-1,hx+6*d,hy-1,6)
 if (s>=21) circfill(hx+8*d,hy-1,1,10) pset(hx+8*d,hy-1,7)
end

-- lights out: remap screen rows of dark floors
function darken()
 local y0,al,w=flr(cy),dark(flo(p.y)),min(63,(255-flr(cx))\2)
 if (w<0) return
 for sy=8,127 do
  local f=(sy-8+y0)\32
  if f>0 and f<=nf and (al or dark(f)) then
   local a=0x6000+sy*64
   for i=a,a+w do poke(i,bm[@i]) end
  end
 end
end

function hud()
 rectfill(0,0,127,7,0)
 print(sc(score),1,1,7)
 print("hi "..sc(hi),30,1,9)
 spr(97,70,0) print(got.."/"..plans,79,1,10)
 for i=1,lives do spr(96,128-i*9,0) end
 if (mt>0) cprint(mtx,112,mt%10<7 and 7 or 10)
 if (mode=="over") cprint("game over",60,8)
 if mode=="esc" and et>200 then
  cprint("mission complete!",44,10)
  cprint("bonus "..lvl*1000,56,7)
  if (t%30<20) cprint("press button",70,6)
 end
end
