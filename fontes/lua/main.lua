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
