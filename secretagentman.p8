pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- secret agent man
-- arcade spy action
-- main: state, helpers and the pico-8 callbacks

nf,ww=12,344
wk=split"1,2,32,33,34,35"
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
  -- blood spray: falls and stains the floor for a moment
  for q in all(gore) do
   q.vy+=.15 q.x+=q.vx q.y+=q.vy q.l-=1
   if (q.y>=q.fy) q.y,q.vx,q.vy=q.fy,0,0
   if (q.l<0) del(gore,q)
  end
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
  -- exhaust smoke: a puff on ignition, a thick trail while pulling away
  if (et>50 and et<150 and (et<110 or et%3==0)) add(smk,{x=carx+1,y=413,r=1,l=24})
  for q in all(smk) do
   q.x-=.4 q.y-=.15 q.r+=.1 q.l-=1
   if (q.l<0) del(smk,q)
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

function _draw()
 cls()
 palt(0,false) palt(14,true)
 if mode=="title" then drtitle() else drworld() hud() end
 -- invincible toggle notice, fades out in 1s
 if (it>0) cprint("invincible mode "..(inv and "on" or "off"),60,it>20 and 7 or it>12 and 6 or it>6 and 13 or 5)
end
-->8
-- level: building layout and entities

function newgame()
 score,lives,lvl=0,3,1
 setup()
end

function setup()
 mode,t="play",0
 shafts,escs,doors,lamps,lit,ens,bul,pops,smk,gore={},{},{},{},{[0]=true},{},{},{},{},{}
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
-->8
-- physics: movement shared by the player and enemies, lifts

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

function kill(e,why,b)
 if (e.st=="dead" or e==p and inv) return
 -- bodies keep riding the lift they died on
 e.rd=e.st=="car" and 0 or e.st=="roof" and 32 or nil
 -- kd: the way the body is thrown; ag: frames spent agonizing before the fall
 e.kd,e.ag,e.why=b and sgn(b.dx) or -e.dir,why=="shot" and 18 or 0,why
 if b then
  for i=1,12 do add(gore,{x=e.x,y=b.y,fy=e.y,vx=e.kd*rnd(1.8)+rnd(.6)-.3,vy=-rnd(1.6),l=30+rnd(20)}) end
 end
 -- crushed: blood squirts out to both sides
 if (why=="crush") for i=1,14 do add(gore,{x=e.x,y=e.y-3,fy=e.y,vx=rnd(4)-2,vy=-rnd(.8),l=40+rnd(20)}) end
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
 elseif e.dt<e.ag+8 then e.x=mid(12,e.x+e.kd*(e.dt<e.ag and .15 or .75),248) end
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
    -- lift doors are always open: no car on this floor means a fall
    local ff=feet(e.f)
    e.sh=s
    -- boarding steps fully inside, past the exit edge (else the next
    -- frame would walk straight back out and the player looked stuck)
    if s.y==ff then e.st,e.x="car",mid(s.x+5,e.x,s.x+18)
    elseif s.y-32==ff then e.st,e.x="roof",mid(s.x+5,e.x,s.x+18)
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
   s.v=btn(2) and f>s.t and -2 or btn(3) and f<s.b and 2 or 0
  elseif s.v==0 then
   -- the player standing near the shaft calls the car to their floor
   -- (not when its roof is already level with that floor: it can be ridden)
   local call=p.st=="walk" and p.f>=s.t and p.f<=s.b and abs(p.x-s.x-12)<48 and s.y-32~=feet(p.f)
   s.w-=1
   if call or s.w<=0 then
    s.tg=call and p.f or s.t+flr(rnd(s.b-s.t+1))
    -- a called car comes at double speed so the player isn't left waiting
    s.v=(s.tg>f and 1 or s.tg<f and -1 or 0)*(call and 2 or 1)
    s.w=30
   end
  -- stop at the target, and always at the ends of the shaft: a car the player
  -- left while it was moving keeps an old target behind it and used to fly off
  elseif f==s.tg or f<=s.t and s.v<0 or f>=s.b and s.v>0 then
   s.v,s.w=0,40+rnd(80)
  end
  if (ov~=0 and s.v==0) sfx(6)
 end
 s.y+=s.v
end
-->8
-- actors: player, enemies, bullets, spawning, camera

function fire(e,pl)
 add(bul,{x=e.x+e.dir*16,y=e.y-e.jy-(e.cr and 5 or 15),dx=e.dir*(pl and 3 or 2),pl=pl,l=60})
 e.sht=24
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
 -- up/down at the lift door also boards a car waiting on this floor
 if e.st=="walk" and e.jy==0 and (btnp(2) or btnp(3)) then
  local s=shaft(e.x+e.dir*4,e.f)
  if (s and s.y==feet(e.f) and s.v==0) e.st,e.sh,e.x="car",s,s.x+12 return
 end
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
  if (e.dt>80) del(ens,e)
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
    -- draw and aim before firing (a warning for the player)
    e.dw=(e.dw or 14)-1
    if e.dw<1 then
     fire(e,false)
     e.dw,e.cd=nil,max(20,70-lvl*8)+rnd(60)
    end
   elseif e.sht<0 and abs(dx)>24 and e.tt%60<30 then
    mx=e.dir
   end
  end
 else
  e.dw=nil
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
    if (hit(e,b)) kill(e,"shot",b) del(bul,b)
   end
  elseif hit(p,b) then
   kill(p,"shot",b) del(bul,b)
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
-->8
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

-- 16x24 character with an adaptive rim: only where a dark part of the
-- character (suit, legs, hat) touches a dark background (grey walls, black
-- shafts, dark doorways) is that edge pixel lit, so it never outlines
-- the figure against the bright walls and sky.
-- the edge pixels of each frame are worked out once and cached in oc
oc={}
function ospr(n,x,y,w,h,fl)
 local k,sx,sy=n*2+(fl and 1 or 0),n%16*8,n\16*8
 local function px(c,r)
  if (c<0 or c>15 or r<0 or r>23) return 14
  return sget(sx+(fl and 15-c or c),sy+r)
 end
 local function dk(c,r) local v=px(c,r) return v==0 or v==5 end
 if not oc[k] then
  oc[k]={}
  for r=-1,24 do for c=-1,16 do
   if (px(c,r)==14 and (dk(c-1,r) or dk(c+1,r) or dk(c,r-1) or dk(c,r+1))) add(oc[k],{c,r})
  end end
 end
 for q in all(oc[k]) do
  local b=pget(x+q[1],y+q[2])
  if (b<3 or b==5) pset(x+q[1],y+q[2],13)
 end
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

-- a black pistol with a long barrel, bigger than the sprite has room for.
-- like the character rim, a pixel over a dark background is drawn light grey
-- so the gun never vanishes; the muzzle flash comes out of its tip
function drgun(e,f,y,s)
 local hr,hc
 if f==5 then hr,hc=20,14
 elseif f==27 or f==28 then hr,hc=12,13
 elseif f==3 or f==11 or f==14 then hr,hc=10,14
 else return end
 local d=e.dir
 local hx,hy=e.x-8+(d>0 and hc or 15-hc),y-24+hr
 local function g(i,j)
  local x,y=hx+i*d,hy+j
  local b=pget(x,y)
  pset(x,y,(b<3 or b==5) and 6 or 0)
 end
 -- grip, frame and trigger guard, then the slide and long barrel
 g(0,1) g(1,1) g(1,0) g(2,0) g(3,0)
 for i=1,9 do g(i,-1) end
 if (s>=21) circfill(hx+11*d,hy-1,1,10) pset(hx+11*d,hy-1,7)
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
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee4444eeeeeeeeeeee4444eeeeeeeeeeee4444eeeeeeeeeeee4444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444eeeeeeeeeeeeeeeeeeeeee
eeeee444444eeeeeeeeee444444eeeeeeeeee444444eeeeeeeeee444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeeeeeeeeeeeeeee
eeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeeeeeeeeeeeeeee
eeeee4fff0feeeeeeeeee4fff0feeeeeeeeee4fff0feeeeeeeeee4fff0feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4fff0feeeeeeeeeeeeeeeeeeeee
eeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeeeeeeeeeeeeeee
eeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffeeeeeeeeeeeeeeeeeeeeee
eeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffeeeeeeeeeeeeeeeeeeeeeee
eeeee0828000eeeeeeeee0828000eeeeeeeee0828000eeeeeeeee0828000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0828000eeeeeeeeeeeeeeeeeeee
eeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee00777000ee55eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00777000eeeeeeeeeeeeeeeeeeee
eeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee0077700000f5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00777000eeeeeeeeeeeeeeeeeeee
eeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00070000eeeeeeeeeeeeeeeeeeee
eeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeeeee4444eeeeeeeeeeee4444eeeeeeeeee00070000eeeeeeeeeeeeeeeeeeee
eeee0007f000eeeeeeee0f070000eeeeeeee00f70000eeeeeeee0007f000eeeeeeeee444444eeeeeeeeee444444eeeeeeeee0007f000eeeeeeeeeeeeeeeeeeee
eeee00000000eeeeeeee00000000eeeeeeee00000000eeeeeeee00000000eeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeee00000000eeeeeeeeeeeeeeeeeeee
eeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee4fff0feeeeeeeeee4fff0feeeeeeeeee000000eeeeeeeeeeeeeeeeeeeee
eeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeee000000eeeeeeeeeeeeeeeeeeeee
eeeee00e00eeeeeeeeeee550000eeeeeeeeee550000eeeeeeeeee00e00eeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeee0000000eeeeeeeeeeeeeeeeeeeee
eeeee00e00eeeeeeeeee55eeee00eeeeeeeee55ee00eeeeeeeeee00e00eeeeeeeeee00828000eeeeeeee00828000eeeeeee000eee000eeeeeeeeeeeeeeeeeeee
eeeee00e00eeeeeeeeee55eeeee00eeeeeee55eee00eeeeeeeeee00e00eeeeeeeee0007770000eeeeee0007770000e55eee00eeeee00eeeeeeeeeeeeeeeeeeee
eeeee00e00eeeeeeeee55eeeeee00eeeeee555eee00eeeeeeeeee00e00eeeeeeeee00077700f0eeeeee00077700000f5eeee00eee00eeeeeeeeeeeeeeeee444e
eeeee00e00eeeeeeeee55eeeeeee00eeee55eeeee00eeeeeeeeee00e00eeeeeeeee00000000000eeeee00000000000eeeeee000ee000eeeeee00000000077ff4
eeeee00e00eeeeeeee55eeeeeeee00eeee5eeeeee00eeeeeeeeee00e00eeeeeeeee00eeeee000eeeeee00eeeee000eeeeeeeeeeeeeeeeeeee000000000007ff4
eeeee000e000eeeeee555eeeeeee000eeeeeeeeee000eeeeeeeee000e000eeeeee000eeeee0000eeee000eeeee0000eeeeeeeeeeeeeeeeeeee000ee0000eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444eeeeeeeeeee444444eeeee
eeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeee44444444eeee
eeeeee55555eeeeeeeeeee55555eeeeeeeeeee55555eeeeeeeeeee55555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeee44ffff44e666
eeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4fff0feeeeeeeee4ffffff4e606
eeeeeefff0feeeeeeeeeeefff0feeeeeeeeeeefff0feeeeeeeeeeefff0feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeeef00ff00fe666
eeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffeeeeeeeeeeffffffffeffe
eeeee00fff0eeeeeeeeee00fff0eeeeeeeeee00fff0eeeeeeeeee00fff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffeeeeeeeeeeeeffffffeeffe
eeee0000f000eeeeeeee0000f000eeeeeeee0000f000eeeeeeee0000f000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0828000eeeeeeeeeeffffee000e
eeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000e55eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00777000ee55eee00077770000ee
eeee000000000eeeeeee000000000eeeeeee000000000eeeeeee0000000000f5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0077700000f5ee00088288000eee
eeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00070000eeeeee00007777000eee
eeee005555500eeeeeee005555500eeeeeee005555500eeeeeee005555500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00070000eeeeee0000077700eeee
eeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0007f000eeeeee0e00077700eeee
eeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeee0e00007000eeee
eee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeefe00000000eeee
eee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeee00000000eeee
eee00000000000eeeee00000000000eeeee00000000000eeeee00000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000eeeeeeeee00000000eeee
eee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000eee000eeeeeeee000ee000eeee
eeeee00e00eeeeeeeeee55eeeee00eeeeeee55eee00eeeeeeeeee00e00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeee00eeeeeeee000ee000eeee
eeeee00e00eeeeeeeee55eeeeee00eeeeee555eee00eeeeeeeeee00e00eeeeeeeeeeeeeeeee000eeeeeeeeeeeeeeeeeeeeee00eee00eeeeeeeee000ee000eeee
eeeee00e00eeeeeeeee55eeeeeee00eeee55eeeee00eeeeeeeeee00e00eeeeeee0000000000ffeeeeeeeeeeeeeeeeeeeeeee000ee000eeeeeeee000ee000eeee
eeeee00e00eeeeeeee55eeeeeeee00eeee5eeeeee00eeeeeeeeee00e00eeeeee00000000000ffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000ee000eeee
eeeee000e000eeeeee555eeeeeee000eeeeeeeeee000eeeeeeeee000e000eeeee00ee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000ee0000eee
e444444eeeeeeeeeeeeeee111178871111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44444444999eeeeeeee111111178871111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
4ffffff49aa9999ee1111111117887111111111eeeeeeeee77777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
f0ffff0f9aaaaaa9777777777778877777777777eeeeeee7777777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ffffffff9aaaaaa9888888888888888888888888eeeeeee5cccc5ccccccc5cccc5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
effffffe9aaaaaa9777777777778877777777777eeeeeee5cccc5ccccccc5ccccc5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0770ee9aaaaaa9111111111178871111111111eeeeeee5cccc5ccccccc5cccccc5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e007700e9999999911ee1111117887111111ee11eebbbbbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5333333333333333333333333333aa5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5333333333353333333333333333335eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee85333333333353333337333333333335eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee85333333333353333333333333333335eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66655555555555555555555555556666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eeeeeeee0000000eeeeeeee0eeee00000000000eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eeeeee000000000eefff4ee0eeee000000500000ef0500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000eff0f44e0000000000050000ff00500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e000000000f00778fffff44ee00000000055500ffff0500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eeeeee000777772fffff44e0eeee00000050000fff0500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000778ef4f444e00000000000500000ff0500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000ee4444ee00000000000000000ee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee000000eeeeeeeeeeeeee00000000000eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444eeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeeeee55555eeeeeeeeeeeee4444eeeeeeeeeeee00000eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4fff0feeeeeeeee000000000eeeeeeeeee444444eeeeeeeeeee00000eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeee44ffffeeeeeeeeeeefff0feeeeeeeeeeee44ffffeeeeeeeeeee55555eeeeeeeeeeeeeeeeeee
e444eeeeeeeeeeeeeeeeeeeee000e0eeeeeeeeeeeeeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeee4fff0feeeeeeeee000000000eeeeeeeeeeeeeeeee
444ffeeeeeeeeeeeeeeeeeee00050eeeeeeeeeeeeeeeeeeeeeeeeeeffeeeeeeeeeeee00fff0eeeeeeeeeeee44ffffeeeeeeeeeeefff0feeeeeeeeeeeeeeeeeee
44f0ffeeeeeeeeeeeeeeeeee0050ffeeeeeeeeeeeeeeeeeeeeeee0828000eeeeeeee0000f000eeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeeeeeeeee
4ffffeeeeeeeeeeeeeeeeeee050f0e0ee0eeeeeeeeeeeeeeeeee00777000eeeeeeee000000000eeeeeeeeeeeeffeeeeeeeeeeee00fff0eeeeeeeeeeeeeeeeeee
4ffffee00eeeeeeeeeeeeeeee0ffff00000eeeeeeeeeeeeeeeee007770000eeeeeee0000000000eeeeeeee0828000eeeeeeee0000f000eeeeeeeeeeeeeeeeeee
444fff0000eeeeeeeeeeeeee0effff0000e0eeeeeeeeeeeeeeee0007000000eeeeee00005000000eeeeee00777000eeeeeeee000000000eeeeeeeeeeeeeeeeee
e4eef870000eeeeeeeeeeeeeeee0ff000000eeeeeeeeeeeeeeee00070000ef55eeee005555500f55eeeee00777f00eeeeeeee000000000eeeeeeeeeeeeeeeeee
eeee87770000eeeeeeeeeeeeee000000055000eeeeeeeeeeeeee00070000eeeeeeee00005000eeeeeeeee00078000eeeeeeee00005f00eeeeeeeeeeeeeeeeeee
eee007700000eeeeeeeeeeeeeee0000555000000eeeeeeeeeeee00000000eeeeeeee000000000eeeeeeee00070000eeeeeeee005585500eeeeeeeeeeeeeeeeee
eee000070f000eeeeeeeeeeeeee0000555000000eeeeeeeeeeeee000000eeeeeeee0000000000eeeeeeee00070000eeeeeeee00005000eeeeeeeeeeeeeeeeeee
eeee000070000eeeeeeeeeeeeeee000500000000eeeeeeeeeeeee000000eeeeeeee0000000000eeeeeeee00000000eeeeeeee000000000eeeeeeeeeeeeeeeeee
eeeee00000000eeeeeeeeeeeeeeee0000000000eeeeeeeeeeeeee00e00eeeeeeeee00000000000eeeeeeee000000eeeeeeee0000000000eeeeeeeeeeeeeeeeee
eeeeee00000000eeeeeeeeeeeeeeee00000000eeeeeeeeeeeeeee00e00eeeeeeeee0000000000eeeeeeeee000000eeeeeeee0000000000eeeeeeeeeeeeeeeeee
eeeeeeee000e000eeeeeeeeeeeeeeee00000000eeeeeeeeeeeeee00e00eeeeeeeeeee00e00eeeeeeeeeeee00ee00eeeeeeee00000000000eeeeeeeeeeeeeeeee
eeeeeeeee000e000ee0eeeeeeeeeee000000e000ee0eeeeeeeeee00e00eeeeeeeeeee00e00eeeeeeeeeee00eee00eeeeeeee0000000000eeeeeeeeeeeeeeeeee
eeeeeeeeee000e0000eeeeeeeeeeeee000000e0000eeeeeeeeeee00e00eeeeeeeeeee00e00eeeeeeeeee00eeee00eeeeeeee00eee00eeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee000e0eeeeeeeeeeeeeeee00e000e0eeeeeeeeeeeee00e00eeeeeeeeeee00e00eeeeeeeeee00eeee00eeeeeee00eeee00eeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeeee000e000eeeeeeeee000e000eeeeeee000eee000eeeeee000eee000eeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee4444eeeeeeeeeeee4444eeeeeeeeeeee4444eeeeeeeeeeee4444eeeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeee
eeeee444444eeeeeeeeee444444eeeeeeeeee444444eeeeeeeeee444444eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeeeeeeeee00000eeeee
eeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeeee55555eeeeeeeeeee55555eeeeeeeeeee55555eeeeeeeeeee55555eeeee
eeeee4fff0feeeeeeeeee4fff0feeeeeeeeee4fff0feeeeeeeeee4fff0feeeeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eee
eeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeee44ffffeeeeeeeeeeefff0feeeeeeeeeeefff0feeeeeeeeeeefff0feeeeeeeeeeefff0feeeee
eeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeeeeeeeeeffffeeeeee
eeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeeeeeffeeeeeeeeeeee00fff0eeeeeeeeee00fff0eeeeeeeeee00fff0eeeeeeeeee00fff0eeeee
eeeee0828000eeeeeeeee0828000eeeeeeeee0828000eeeeeeeee0828000eeeeeeee0000f000eeeeeeee0000f000eeeeeeee0000f000eeeeeeee0000f000eeee
eeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eee
eeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee00777000eeeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eee
eeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeee
eeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee00070000eeeeeeee005555500eeeeeee005555500eeeeeee005555500eeeeeee005555500eee
eeee0007f000eeeeeeee000700f0eeeeeeee00070f00eeeeeeee0007f000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeeeeeee00005000eeee
eeee00000000eeeeeeee00000000eeeeeeee00000000eeeeeeee00000000eeeeeeee000000000eeeeeee000000000eeeeeee000000000eeeeeee000000000eee
eeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eee
eeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeeeee000000eeeeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eee
eeeee005555eeeeeeeeee005555eeeeeeeeee005555eeeeeeeeee550000eeeeeeee00000000000eeeee00000000000eeeee00000000000eeeee00000000000ee
eeeeee00e555eeeeeeee00eeee55eeeeeeeee00ee55eeeeeeeeeee55e000eeeeeee0000000000eeeeee0000000000eeeeee0000000000eeeeee0000000000eee
eeeeee00ee55eeeeeeee00eeeee55eeeeeee00eee55eeeeeeeeeee55ee00eeeeeeeeee00ee55eeeeeeee00eeeee55eeeeeee00eee55eeeeeeeeeee55ee00eeee
eeeeee00e55eeeeeeee00eeeeee55eeeeee000eee55eeeeeeeeeee55e00eeeeeeeeeee00e55eeeeeeee00eeeeee55eeeeee000eee55eeeeeeeeeee55e00eeeee
eeeeee00e5eeeeeeeee00eeeeeee55eeee00eeeee55eeeeeeeeeee55e0eeeeeeeeeeee00e5eeeeeeeee00eeeeeee55eeee00eeeee55eeeeeeeeeee55e0eeeeee
eeeeee00eeeeeeeeee00eeeeeeee55eeee0eeeeee55eeeeeeeeeee55eeeeeeeeeeeeee00eeeeeeeeee00eeeeeeee55eeee0eeeeee55eeeeeeeeeee55eeeeeeee
eeeeee0000eeeeeeee000eeeeeee555eeeeeeeeee555eeeeeeeeee5555eeeeeeeeeeee0000eeeeeeee000eeeeeee555eeeeeeeeee555eeeeeeeeee5555eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__sfx__
000300003c67030660246451e62500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000034660286501e6350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000024350213501e3401a34016330123250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600002825025250222501f2501c250192501625013250102500d2500a235000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000024450284502b4503045030445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003f6503a6403d630376303c625326150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00002d05029045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000184311e431244212841500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000283502f350343503433500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000146730e2730a6630825506645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000082500823009250092300a2500a2300b2500b2300c2500c2300d2500d2300e2500e2300f2500f23010250102301125011230122501223013250132300000000000000000000000000000000000000000
000800001c4501f450234502745028452284422843228425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000e73112731107250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00002825026250232501f2521f2421f2350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00000415000000041500000007150000000415000000091500000004150000000a15000000091500000004150000000415000000071500000004150000000e150000000b1500000009150000000715000000
000d0000091500000009150000000c1500000009150000000e1500000009150000000f150000000e15000000091500000009150000000c150000000915000000131500000010150000000e150000000c15000000
000d00000b150000000b150000000e150000000b1500000010150000000b1500000011150000001015000000091500000009150000000c1500000009150000000e1500000009150000000f150000000e15000000
000d000010363000003c6250000026655000003c625000001036300000103633c62526655000003c6253c62510363000003c6250000026655000003c625000001036300000103633c62526655000003c6253c625
000d000010363000003c6250000026635000003c625000001036300000103633c62526655000003c6253c62510363000003c62500000266650000026665000002667526675266752667526675266752667526675
000d000028440284422844200000264402844000000234402344223442234420000021440214421f440000001c4401c442000001f4401f4420000021440000002244022442234402344223442234420000000000
000d00002844028420284402842026440264202644026420234402342023440234202144021420234402342026440264202644026420234402342021440214201f4401f4201c4401c4201c4401c4200000000000
000d00002d4402d4422d442000002b4402d4400000028440284422844228442000002644026442244400000021440214420000024440244420000026440000002744027442284402844228442284420000000000
000d00002a4402a4422a4422a4422d4402d4422a4402a442274402744227442274422344023442234420000024440244422444224442284402844224440244422144021442234402344228440284422844200000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 10134040
01 10131540
00 10131640
00 11131740
00 10131540
02 12141840
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
00 40404040
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077770077777700007777007777770077777700777777000000000077777700007777007777770077770000777777000000000000000000
00000000000000000077770077777700007777007777770077777700777777000000000077777700007777007777770077770000777777000000000000000000
00000000000000007700000077000000770000007700770077000000007700000000000077007700770000007700000077007700007700000000000000000000
00000000000000007700000077000000770000007700770077000000007700000000000077007700770000007700000077007700007700000000000000000000
00000000000000007777770077770000770000007777000077770000007700000000000077777700770000007777000077007700007700000000000000000000
00000000000000007777770077770000770000007777000077770000007700000000000077777700770000007777000077007700007700000000000000000000
00000000000000000000770077000000770000007700770077000000007700000000000077007700770077007700000077007700007700000000000000000000
00000000000000000000770077000000770000007700770077000000007700000000000077007700770077007700000077007700007700000000000000000000
00000000000000007777000077777700007777007700770077777700007700000000000077007700777777007777770077007700007700000000000000000000
00000000000000007777000077777700007777007700770077777700007700000000000077007700777777007777770077007700007700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008888880088888800888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008888880088888800888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008888880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008888880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088888800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088888800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008800880088008800880088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000555555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005555555555555555555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005555555666666666665555555000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005555556666666666666666665555555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055556665566666666666666666566555500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005555666666655666666666666666566665555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000055566666666666556666666666666656666655500000000000000000000000000000000000000000000
00000000000000000000000000000000000000000005555666666666666665566666666666665666665555000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055566666666666666777755777776666665666666655500000000000000000000000000000000000000000
00000000000000000000000000000000000000000555666666666666777777777777777776666566666665550000000000000000000000000000000000000000
00000000000000000000000000000000000000005556666666666777777777777777777777776656666666555000000000000000000000000000000000000000
00000000000000000000000000000000000000055566666666677777777777777777777777777756666666655500000000000000000000000000000000000000
00000000000000000000000000000000000000554444444456777777777777777777777777777775666666665550000000000000000000000000000000000000
00000000000000000000000000000000000005554444444467777777777777777777777777777777666666666555000000000000000000000000000000000000
00000000000000000000000000000000000005444444444444777777777777777777777777777777776666666655000000000000000000000000000000000000
00000000000000000000000000000000000055444444444444777777777777777777777777777777777666666565500000000000000000000000000000000000
000000000000000000000000000000000005554444ffffffff777777777777777777777777777777777766666565550000000000000000000000000000000000
000000000000000000000000000000000005564444ffffffff777777777777777777777777777777777776666566550000000000000000000000000000000000
0000000000000000000000000000000000556644ffffff00ff777777777777777777777777777777777776666566655000000000000000000000000000000000
0000000000000000000000000000000005556644ffffff00ff777777777777777777777777777777777777666566655500000000000000000000000000000000
000000000000000000000000000000000556664444ffffffff777777777777777777777777777777777777766566665500000000000000000000000000000000
000000000000000000000000000000000556664444ffffffff777777777777777777777777777777777777775666665500000000000000000000000000000000
0000000000000000000000000000000055666666ffffffff77777777777777777777777777777777777777775666666550000000000000000000000000000000
0000000000000000000000000000000055666666ffffffff77777777777777777777777777777777777777775666666550000000000000000000000000000000
000000000000000000000000000000005566666677ffff7777777777777777777777777777777777777777775666666550000000000000000000000000000000
000000000000000000000000000000055666666577ffff7777777777777777777777777777777777777777775666666655000000000000000000000000000000
00000000000000000000000000000005566666007777770000007777777777777777777777777777777777777766666655000000000000000000000000000000
00000000000000000000000000000005566665007777770000007777777777777777777777777777777777777766666655000000000000000000000000000000
00000000000000000000000000000005566600007700770000007777777777777777777777777777777777777766666655000000000000000000000000000000
00000000000000000000000000000055666600007700770000007777777777777777777777777777777777777776666665500000000000000000000000000000
00000000000000000000000000000055666500007777770000007777777777777777777777777777777777777776666665500000000000000000000000000000
00000000000000000000000000000055665600007777770000007777777777777777777777777777777777777776666665500000000000000000000000000000
00000000000000000000000000000055665600000077000000007777777777777777777777777777777777777776666665500000000000000000000000000000
00000000000000000000000000000055656600000077000000007777777777777777777777777777777777777776666665500000000000000000000000000000
00000000000000000000000000000055566600000077000000007777777777777777777777777777777777777776666655500000000000000000000000000000
00000000000000000000000000000055666600000077000000007777777777777777777777777777777777777776666565500000000000000000000000000000
00000000000000000000000000000055666600000077ff0000007777777777777777777777777777777777777776665665500000000000000000000000000000
00000000000000000000000000000055666600000077ff0000007777777777777777777777777777777777777776656665500000000000000000000000000000
00000000000000000000000000000055666600000000000000007777777777777777777777777777777777777776566665500000000000000000000000000000
00000000000000000000000000000055666600000000000000007777777777777777777777777777777777777775666665500000000000000000000000000000
00000000000000000000000000000005566666000000000000777777777777777777777777777777777777777756666655000000000000000000000000000000
00000000000000000000000000000005566666000000000000777777777777777777777777777777777777777566666655000000000000000000000000000000
00000000000000000000000000000005566666000000000000777777777777777777777777777777777777775766666655000000000000000000000000000000
00000000000000000000000000000005566666000000000000777777777777777777777777777777777777777666666655000000000000000000000000000000
00000000000000000000000000000000556666000000000000777777777777777777777777777777777777777666666550000000000000000000000000000000
00000000000000000000000000000000556666000000000000777777777777777777777777777777777777777666666550000000000000000000000000000000
00000000000000000000000000000000556600000077770000777777777777777777777777777777777777776666666550000000000000000000000000000000
00000000000000000000000000000000055600000077770000777777777777777777777777777777777777776666665500000000000000000000000000000000
00000000000000000000000000000000055600006677777700007777777777777777777777777777777777766666665500000000000000000000000000000000
00000000000000000000000000000000055500006667777700007777777777777777777777777777777777666666655500000000000000000000000000000000
00000000000000000000000000000000000000566666777700007777777777777777777777777777777776666666655000000000000000000000000000000000
00000000000000000000000000000000000000566666777700007777777777777777777777777777777776666666550000000000000000000000000000000000
00000000000000000000000000000000000000566666677777000077777777777777777777777777777766665565550000000000000000000000000000000000
00000000000000000000000000000000000000666666667777000077777777777777777777777777777655556665500000000000000000000000000000000000
00000000000000000000000000000000000005566666666777000077777777777777777777777777755566666655000000000000000000000000000000000000
00000000000000000000000000000000000005556666666657000077777777777777777777777775566666666555000000000000000000000000000000000000
00000000000000000000000000000000000000555666666665000000777777777777777777777776666666665550000000000000000000000000000000000000
00000000000000000000000000000000000000055566666665000000777777777777777777777766666666655500000000000000000000000000000000000000
00000000000000000000000000000000000000005556666666566777777777777777777777776666666666555000000000000000000000000000000000000000
00000000000000000000000000000000000000000555666666656666777777777777777776666666666665550000000000000000000000000000000000000000
00000000000000000000000000000000000000000055566666656666666777775577776666666666666655500000000000000000000000000000000000000000
00000000000000000000000000000000000000000005555666665666666666666655666666666666665555000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000055566666566666666666666556666666666655500000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005555666566666666666666665566666665555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055556656666666666666666655666555500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005555556666666666666666666555555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005555555666666666665555555000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005555555555555555555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000555555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077707070077070700000777070707770777007707700000077700770000007707770777077707770000000000000000000000000
00000000000000000000000070707070700070700000707070700700070070707070000007007070000070000700707070700700000000000000000000000000
00000000000000000000000077707070777077700000770070700700070070707070000007007070000077700700777077000700000000000000000000000000
00000000000000000000000070007070007070700000707070700700070070707070000007007070000000700700707070700700000000000000000000000000
00000000000000000000000070000770770070700000777007700700070077007070000007007700000077000700707070700700000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000009090999000000990099009909990999000009990999099909990999099900000000000000000000000000000000000
00000000000000000000000000000000009090090000009000900090909090900000009090909000909090900090900000000000000000000000000000000000
00000000000000000000000000000000009990090099909990900090909900990000009090909099909990999090900000000000000000000000000000000000
00000000000000000000000000000000009090090000000090900090909090900000009090909090000090009090900000000000000000000000000000000000
00000000000000000000000000000000009090999000009900099099009090999000009990999099900090999099900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005550000055505550555055500000505000005550505055505550000005555500055555000000500055505550555000500550555055505550555005500000
00000050050050000500505050000000505005000500505055505050000055505550550005500500500005005000050005005000050050500500505050000000
00000500000055000500550055000000050000000500505050505550000055000550550005500000500005005500050005005550050055500500550055500000
00005000050050000500505050000000505005000500505050505000000055000550555055500500500005005000050005000050050050500500505000500000
00005550000050005550505055500000505000005500055050505000000005555500055555000000555055505000050050005500050050505550505055000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

