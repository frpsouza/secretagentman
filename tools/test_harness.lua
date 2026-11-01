-- test harness: scripted input, screen dumps
fk,fkp=0,0
btn=function(i) return fk&(1<<i)~=0 end
btnp=function(i) return fkp&(1<<i)~=0 end
function dump(name)
 printh("@@"..name)
 for y=0,127 do local r="" for x=0,127 do local c=pget(x,y) r=r..sub("0123456789abcdef",c+1,c+1) end printh(r) end
end
function step(n,b,bp)
 for i=1,n do
  fk=b or 0
  fkp=(i==1 and bp) or 0
  _update() _draw()
 end
end
function log(s) printh("LOG "..s) end
srand(3)
_init()
step(60) dump("title")
step(1,0,16) step(40)
step(60) dump("para")
step(120)
dump("roof")
-- walk right to escalator at 216
step(160,2)
log("roof x="..p.x.." st="..p.st)
step(60,8)
log("after esc st="..p.st.." f="..p.f.." x="..p.x)
dump("floor1")
-- go left toward shaft A, shoot along the way
for i=1,6 do step(10,1,16) end
step(60,1)
log("near shaft st="..p.st.." f="..p.f.." x="..p.x.." y="..p.y)
dump("shaft")
-- teleport into car of shaft c and ride
local s=shafts[3]
s.y=feet(6) s.v=0
p.x,p.y,p.f,p.st,p.sh=204,feet(6),6,"car",s
step(5,8) step(80,8)
log("car ride y="..p.y.." st="..p.st.." sy="..s.y)
dump("car")
-- force enemies & dark floor
p.x,p.f,p.y,p.st=150,7,feet(7),"walk"
for i=1,3 do spt=0 spawn() end
step(40)
log("enemies "..#ens)
dump("enemies")
-- jump shoot lamp
p.x=160 p.dir=1 cx=p.x-64
step(1,0,32) step(3) step(1,0,16) step(30)
log("lit7="..tostr(lit[7]))
dump("dark")
-- crouch for a while under fire
step(120,8)
log("after crouch st="..p.st.." lives="..lives)
-- red door on floor 8 x=64
p.x,p.f,p.y,p.st=70,8,feet(8),"walk" ens={}
step(1,0,4) step(30) dump("door") step(40)
log("got="..got)
-- escape test
got=plans p.x,p.f,p.y,p.st=230,12,feet(12),"walk" ens={}
step(40,2)
log("mode="..mode)
step(120) dump("escape")
step(150) dump("complete")
log("score="..score)
-- run long random play
srand(7)
step(1,0,16)
for i=1,3000 do
 local b=flr(rnd(64))
 fk=b fkp=flr(rnd(64))
 _update() _draw()
 if mode=="title" then fkp=16 end
end
log("random done mode="..mode.." lives="..tostr(lives))
dump("random")
log("ok")

