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
 cx,cy,spt,mt,carx,ta,ck,cdo=0,-48,300,0,296,nil,0,0
 msg("mission "..lvl..": find the plans!",120)
end

function newent(x,f)
 return {x=x,f=f,y=feet(f),st="walk",dir=1,jy=0,jv=0,cd=0,sht=0,spd=1,sx=x,sf=f,tt=0,wd=0}
end
