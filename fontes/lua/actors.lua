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
