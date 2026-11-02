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
 -- a long fall onto a car coming up is a crush, not a fall
 if y-e.fy>40 then kill(e,st=="roof" and e.sh.v<0 and "crush" or "fall")
 elseif e==p then sfx(26) end
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
    -- stepping in while the car is passing this floor: caught between the
    -- floor and the car
    elseif s.y-32<ff and s.y>ff-23 then kill(e,"crush")
    elseif e.f<s.b then
     e.st,e.vy,e.fy="fall",0,e.y
     if (e==p) sfx(15)
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
  -- compare with where the roof was last frame: a rising car and a falling
  -- body close in by up to 6px a frame
  if e.y>=ry and e.y-e.vy<=ry-s.v+1 then land(e,ry,"roof")
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
  -- ding-dong when a car stops for the player (riding it, or at their floor)
  if (ov~=0 and s.v==0 and (man or p.st=="walk" and f==p.f and abs(p.x-s.x-12)<48)) sfx(25)
 end
 s.y+=s.v
end
