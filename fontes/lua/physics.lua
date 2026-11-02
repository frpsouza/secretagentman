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
  local ox=e.x
  e.x=mid(12,e.x+mx*e.spd*(e.jy>0 and 2 or 1),e.xr or 244)
  if e.jy==0 then
   s=shaft(e.x,e.f)
   if s then
    local ff,ok=feet(e.f),s.v==0 or e~=p
    e.sh=s
    if s.y==ff and ok then e.st="car"
    elseif s.y-32==ff and ok then e.st="roof"
    -- the player waits at the lift door for the car to stop; only jumps fall in
    elseif e==p and not shaft(ox,e.f) then e.x=ox
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
   local call=p.st=="walk" and p.f>=s.t and p.f<=s.b and abs(p.x-s.x-12)<48
   s.w-=1
   if call or s.w<=0 then
    s.tg=call and p.f or s.t+flr(rnd(s.b-s.t+1))
    -- a called car comes at double speed so the player isn't left waiting
    s.v=(s.tg>f and 1 or s.tg<f and -1 or 0)*(call and 2 or 1)
    s.w=30
   end
  elseif f==s.tg then
   s.v,s.w=0,40+rnd(80)
  end
  if (ov~=0 and s.v==0) sfx(6)
 end
 s.y+=s.v
end
