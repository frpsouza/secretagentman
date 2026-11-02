-- secret agent man
-- arcade spy action

nf,ww=12,344
dm=split"0,0,0,1,2,0,5,13,2,4,9,3,1,1,2,4"

function _init()
 cartdata("frps_secretagentman")
 hi=dget(0)
 bm={}
 for b=0,255 do bm[b]=dm[b%16+1]+dm[b\16+1]*16 end
 mus,inv,it=true,false,0
 poke(0x5f2d,1) -- keyboard: i toggles invincible mode
 menuitem(1,"music on/off",function() mus=not mus music(mus and 0 or -1) end)
 title()
end

function title()
 mode,t,stt="title",0,0
 if (mus) music(0)
end

function feet(f) return f*32+32 end
function flo(y) return (y-1)\32 end
function dark(f) return lit[f]==false end
function hgt(e) return e.cr and 12 or 23 end
function msg(s,d) mtx,mt=s,d or 90 end
function pop(x,y,s) add(pops,{x=x,y=y,s=s,t=30}) end
function sc(n) local s=tostr(n) while #s<5 do s="0"..s end return s.."0" end

function addsc(v)
 score+=v
 if (score>hi) hi=score dset(0,hi)
end

function cprint(s,y,c)
 local x=64-#s*2
 print(s,x-1,y,0) print(s,x+1,y,0) print(s,x,y+1,0)
 print(s,x,y,c)
end

function newgame()
 score,lives,lvl=0,3,1
 setup()
end

function setup()
 mode,t="play",0
 shafts,escs,doors,lamps,lit,ens,bul,pops={},{},{},{},{[0]=true},{},{},{}
 for d in all{{96,1,5},{24,3,8},{192,5,10},{112,8,12}} do
  add(shafts,{x=d[1],t=d[2],b=d[3],y=feet(d[2]+flr(rnd(d[3]-d[2]+1))),v=0,w=30})
 end
 -- upper floor,top x,dir
 local d=split"0,216,-1,3,160,1,5,160,-1,6,64,1,9,72,1,10,232,-1,11,160,1"
 for i=1,#d,3 do add(escs,{u=d[i],x=d[i+1],dx=d[i+2]}) end
 -- floor,x,red
 d=split"1,40,0,1,140,0,1,232,0,2,30,1,2,150,0,2,210,0,3,64,0,3,136,0,3,200,0,4,60,1,4,136,0,4,216,0,5,60,0,5,136,0,5,228,0,6,80,1,6,168,0,6,228,0,7,110,0,7,150,0,7,228,0,8,64,1,8,160,0,8,228,0,9,30,0,9,150,0,9,228,0,10,30,1,10,150,0,11,30,0,11,64,1,11,176,0,12,30,0,12,70,0"
 plans,got=0,0
 for i=1,#d,3 do
  add(doors,{f=d[i],x=d[i+1],red=d[i+2]==1,o=0})
  plans+=d[i+2]
 end
 for f=1,nf do
  lit[f]=true
  add(lamps,{f=f,x=72,ok=true})
  add(lamps,{f=f,x=176,ok=true})
 end
 p=newent(64,0)
 p.y,p.st,chute=-56,"para",nil
 cx,cy,spt,mt,carx=0,-48,300,0,296
 msg("mission "..lvl..": find the plans!",120)
end

function newent(x,f)
 return {x=x,f=f,y=feet(f),st="walk",dir=1,jy=0,jv=0,cd=0,sht=0,spd=1,sx=x,sf=f,tt=0,wd=0}
end

function shaft(x,f)
 for s in all(shafts) do
  if (x>s.x+1 and x<s.x+22 and f>=s.t and f<=s.b) return s
 end
end

function findesc(e,u,d)
 for c in all(escs) do
  if (d and c.u==e.f and abs(e.x-c.x)<4) return c,0,1
  if (u and c.u==e.f-1 and abs(e.x-c.x-c.dx*32)<4) return c,32,-1
 end
end

function hidden(e)
 local k=e.dt
 return e.st=="door" and k>8 and k<48 or e.st=="out" and k<8 or e.st=="gone"
end

function hit(e,b)
 local y=e.y-e.jy
 return e.st~="dead" and not hidden(e) and abs(b.x-e.x)<5 and b.y<=y and b.y>=y-hgt(e)
end

function kill(e,why)
 if (e.st=="dead" or e==p and inv) return
 -- bodies keep riding the lift they died on
 e.rd=e.st=="car" and 0 or e.st=="roof" and 32 or nil
 e.st,e.dt,e.jy,e.cr,e.sht="dead",0,0,false,0
 if e==p then
  sfx(why=="crush" and 9 or 3)
 else
  sfx(why=="shot" and 2 or 9)
  local v=why=="shot" and 10 or 30
  addsc(v) pop(e.x,e.y-28,v.."0")
 end
end

-- dead bodies: fly back while falling, keep riding the lift they died on
function knock(e)
 if e.rd then e.y=e.sh.y-e.rd
 elseif e.dt<8 then e.x=mid(12,e.x-e.dir*.75,248) end
end

function land(e,y,st)
 e.y,e.st=y,st
 if (y-e.fy>40) kill(e,"fall")
end

-- shared movement rules (player and enemies)
function act(e,mx,u,d)
 local st,s=e.st,e.sh
 e.mv=mx~=0
 if (mx~=0) e.dir=mx
 if st=="walk" then
  local c,k,ed=findesc(e,u,d)
  if c then e.st,e.es,e.k,e.ed="esc",c,k,ed return end
  -- faster in the air so a jump clears a shaft (24px)
  e.x=mid(12,e.x+mx*e.spd*(e.jy>0 and 2 or 1),e.xr or 244)
  if e.jy==0 then
   s=shaft(e.x,e.f)
   if s then
    local ff=feet(e.f)
    e.sh=s
    if s.y==ff then e.st="car"
    elseif s.y-32==ff then e.st="roof"
    elseif e.f<s.b then e.st,e.vy,e.fy="fall",0,e.y
    elseif s.y>e.y-hgt(e) then kill(e,"crush") end
   end
  end
 elseif st=="esc" then
  local c=e.es
  e.k+=e.ed*.75
  e.dir,e.mv=c.dx*e.ed,true
  if e.k>=32 then e.st,e.f,e.k="walk",c.u+1,32
  elseif e.k<=0 then e.st,e.f,e.k="walk",c.u,0 end
  e.x,e.y=c.x+c.dx*e.k,feet(c.u)+e.k
 elseif st=="fall" then
  e.vy=min(e.vy+.3,4)
  e.y+=e.vy
  local ry,by=s.y-32,feet(s.b)
  if e.y>=ry and e.y-e.vy<=ry+1 then land(e,ry,"roof")
  elseif e.y>=by then e.f=s.b land(e,by,"walk") end
 elseif st=="car" or st=="roof" then
  local rf=st=="roof"
  e.y=s.y-(rf and 32 or 0)
  local nx=e.x+mx*e.spd
  if s.y%32==0 and e.y>s.t*32 and (nx<s.x+5 or nx>s.x+18) then
   -- step clear of the shaft so walk doesn't re-board
   e.st,e.f,nx="walk",flo(e.y),nx<s.x+5 and s.x+1 or s.x+22
  else
   nx=mid(s.x+5,nx,s.x+18)
  end
  e.x=nx
  if (rf and e.y-hgt(e)<s.t*32) kill(e,"crush")
 end
end

function upcar(s)
 local man=p.st=="car" and p.sh==s
 if s.y%32==0 then
  local f,ov=s.y\32-1,s.v
  if man then
   s.v=btn(2) and f>s.t and -1 or btn(3) and f<s.b and 1 or 0
  elseif s.v==0 then
   -- the player standing near the shaft calls the car to their floor
   local call=p.st=="walk" and p.f>=s.t and p.f<=s.b and abs(p.x-s.x-12)<48
   s.w-=1
   if call or s.w<=0 then
    s.tg=call and p.f or s.t+flr(rnd(s.b-s.t+1))
    s.v=s.tg>f and 1 or s.tg<f and -1 or 0
    s.w=30
   end
  elseif f==s.tg then
   s.v,s.w=0,40+rnd(80)
  end
  if (ov~=0 and s.v==0) sfx(6)
 end
 s.y+=s.v
end

function fire(e,pl)
 add(bul,{x=e.x+e.dir*7,y=e.y-e.jy-(e.cr and 4 or 14),dx=e.dir*(pl and 3 or 2),pl=pl,l=60})
 e.sht=8
 sfx(pl and 0 or 1)
end

function upplayer()
 local e=p
 e.cd,e.sht=max(e.cd-1,-1),max(e.sht-1,-1)
 if e.st=="dead" then
  e.dt+=1
  knock(e)
  if e.dt>90 then
   lives-=1
   if lives<1 then
    mode,t="over",0
    music(-1) sfx(14)
   else
    p,ens,bul,spt=newent(e.sx,e.sf),{},{},90
   end
  end
  return
 end
 if e.st=="para" then
  e.y+=.6
  -- the canopy is left behind to collapse on the roof
  if (e.y>=32) e.y,e.st,chute=32,"walk",{x=e.x,d=e.dir,k=0}
  return
 end
 if e.st=="door" then
  e.dt+=1
  local d,k=e.dr,e.dt
  d.o=k<8 and k/8 or k<16 and 2-k/8 or k<40 and 0 or k<48 and k/8-5 or k<56 and 7-k/8 or 0
  if k==30 then
   d.red,got=false,got+1
   addsc(50) sfx(4) pop(e.x,e.y-30,"500")
   if got==plans then
    msg("all plans! escape via lobby!",150) sfx(11)
   else
    msg("plans "..got.."/"..plans)
   end
  end
  if (k>=56) e.st="walk"
  return
 end
 local mx,u,d=(btn(1) and 1 or 0)-(btn(0) and 1 or 0),btn(2),btn(3)
 e.cr=false
 if e.st=="walk" and e.jy==0 then
  if (d and not findesc(e,false,true)) e.cr,mx=true,0
  if btnp(2) and not findesc(e,true,false) then
   for r in all(doors) do
    if r.f==e.f and r.red and abs(e.x-r.x-6)<5 then
     e.st,e.dr,e.dt,e.x="door",r,0,r.x+6
     sfx(12)
     return
    end
   end
  end
  if (btnp(4) and not e.cr) e.jv=2.2 sfx(7)
 end
 e.xr=e.f==nf and got==plans and 252 or 244
 act(e,mx,u,d)
 if e.jv~=0 or e.jy>0 then
  e.jy+=e.jv e.jv-=.3
  if (e.jy<=0) e.jy,e.jv=0,0
 end
 if e.st=="walk" then
  if (e.jy==0 and not shaft(e.x,e.f)) e.sx,e.sf=e.x,e.f
  if e.f==nf and e.x>=244 then
   if got<plans then
    if (mt<1) msg("find all the plans first!",60)
   elseif e.x>=250 then
    mode,et,cv,e.cr="esc",0,0,false
    music(-1)
   end
  end
 end
 if btnp(5) and e.cd<0 and e.st~="fall" and e.st~="dead" then
  local n=0
  for b in all(bul) do if (b.pl) n+=1 end
  if (n<2) fire(e,true) e.cd=8
 end
end

function upenemy(e)
 e.cd,e.sht,e.tt=max(e.cd-1,-1),max(e.sht-1,-1),max(e.tt-1,-1)
 if e.st=="dead" then
  e.dt+=1
  knock(e)
  if (e.dt>45) del(ens,e)
  return
 end
 if e.st=="out" then
  e.dt+=1
  local k=e.dt
  e.dr.o=k<8 and k/8 or k<16 and 1 or k<24 and 3-k/8 or 0
  if (k>=24) e.st="walk"
  return
 end
 local mx,u,d,dx,os=0,false,false,p.x-e.x,e.st
 local same=abs(e.y-p.y)<3 and p.st~="dead" and not hidden(p)
 if same and abs(dx)<(dark(flo(e.y)) and 40 or 100) then
  if e.st~="esc" and e.st~="fall" then
   e.dir=sgn(dx)
   if e.cd<0 then
    fire(e,false)
    e.cd=max(20,70-lvl*8)+rnd(60)
   elseif e.sht<0 and abs(dx)>24 and e.tt%60<30 then
    mx=e.dir
   end
  end
 else
  if (e.tt<0) e.wd,e.tt=rnd{-1,1},60+rnd(90)
  mx,u,d=e.wd,p.y<e.y-8,p.y>e.y+8
 end
 -- most agents avoid open shafts
 if e.st=="walk" and mx~=0 and not e.brave then
  local s,ff=shaft(e.x+mx*8,e.f),feet(e.f)
  if (s and s.y~=ff and s.y-32~=ff and e.f<s.b) mx,e.wd=0,-e.wd
 end
 act(e,mx,u,d)
 if (e.st~=os and (e.st=="car" or e.st=="roof")) e.wd,e.tt=0,40+rnd(100)
 if e.st=="walk" then
  if (e.x<=12 or e.x>=244) e.wd=e.x<128 and 1 or -1
  if (abs(e.y-p.y)>110) del(ens,e)
 end
end

function upbul()
 for b in all(bul) do
  b.x+=b.dx b.l-=1
  local f=b.y\32
  if b.l<0 or b.x<8 or b.x>248 then
   del(bul,b)
  elseif b.pl then
   for l in all(lamps) do
    if l.ok and l.f==f and abs(b.x-l.x)<4 and b.y<f*32+13 then
     l.ok,lit[f]=false,false
     del(bul,b) sfx(5) addsc(5)
    end
   end
   for e in all(ens) do
    if (hit(e,b)) kill(e,"shot") del(bul,b)
   end
  elseif hit(p,b) then
   kill(p,"shot") del(bul,b)
  end
 end
end

function spawn()
 spt-=1
 if (spt>0 or #ens>=min(1+lvl,4) or p.st=="para") return
 spt=60+rnd(max(40,160-lvl*20))
 local c,pf={},flo(p.y)
 for d in all(doors) do
  local ax=abs(d.x+6-p.x)
  if (not d.red and d.o==0 and abs(d.f-pf)<2 and ax>32 and ax<120) add(c,d)
 end
 if #c>0 then
  local d=rnd(c)
  local e=newent(d.x+6,d.f)
  e.st,e.dr,e.dt,e.en,e.brave,e.cd="out",d,0,true,rnd()<.15,30
  e.spd,e.dir=min(.4+lvl*.1,.8),sgn(p.x-e.x)
  add(ens,e)
 end
end

function camfollow(tx)
 tx=mid(0,(tx or p.x)-64,ww-128)
 local ty=mid(-48,p.y-72,312)
 cx+=(tx-cx)*.25 cy+=(ty-cy)*.25
end

function _update()
 t+=1
 it-=1
 while stat(30) do
  if (stat(31)=="i") inv,it=not inv,30
 end
 if mode=="title" then
  if stt>0 then
   stt+=1
   if (stt>30) newgame()
  elseif t>20 and (btnp(4) or btnp(5)) then
   stt=1 sfx(8)
  end
 elseif mode=="play" then
  for s in all(shafts) do upcar(s) end
  if chute then
   chute.k+=1
   if (chute.k>70) chute=nil
  end
  upplayer()
  for e in all(ens) do upenemy(e) end
  upbul()
  spawn()
  for q in all(pops) do
   q.y-=.5 q.t-=1
   if (q.t<0) del(pops,q)
  end
  mt-=1
  camfollow()
 elseif mode=="esc" then
  et+=1
  if et<50 then
   p.x+=1 p.mv,p.dir=true,1
  elseif et==50 then
   p.st="gone" sfx(10)
  elseif et>70 then
   cv+=.08 carx+=cv
  end
  if (et==200) addsc(100*lvl) sfx(11)
  if et>220 and (btnp(4) or btnp(5)) then
   lvl+=1 setup()
   if (mus) music(0)
  end
  mt-=1
  camfollow(et>60 and carx+16)
 elseif t>60 and (btnp(4) or btnp(5)) or t>300 then
  title()
 end
end

-- drawing

function _draw()
 cls()
 palt(0,false) palt(14,true)
 if mode=="title" then drtitle() else drworld() hud() end
 -- invincible toggle notice, fades out in 1s
 if (it>0) cprint("invincible mode "..(inv and "on" or "off"),60,it>20 and 7 or it>12 and 6 or it>6 and 13 or 5)
end

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
 spr(101,carx,400,4,2)
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
  end
 end
end

function drent(e)
 if (hidden(e) or e.st=="dead" and e.dt>25 and t%4<2) return
 local f,y=0,e.y-e.jy
 if e.st=="dead" then
  -- knocked back: tilted mid-fall with a small hop, then lying flat
  local k,sx=e.dt,e.en and 24 or 0
  if k<8 then sspr(sx,72,24,24,e.x-(e.dir<0 and 8 or 16),y-24-k*(8-k)/4,24,24,e.dir<0)
  else sspr(sx,64,24,8,e.x-12,y-8,24,8,e.dir>0) end
  return
 elseif e.cr then f=e.sht>0 and 5 or 4
 elseif e.jy>0 or e.st=="fall" or e.st=="para" then f=e.sht>0 and 14 or 6
 elseif e.sht>0 then f=3
 elseif e.mv then f=1+t\4%2 end
 if (e.en) f=f==3 and 11 or f<3 and f+8 or 8
 if e.st=="para" then
  -- full canopy, breathing with the wind
  local h=11+sin(t/24)*1.5
  sspr(16,48,24,8,e.x-14,y-32-h,28,h)
  line(e.x-13,y-33,e.x-4,y-20,6) line(e.x+13,y-33,e.x+3,y-20,6)
 end
 spr(f\8*48+f%8*2,e.x-8,y-24,2,3,e.dir<0)
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
