'use strict';
// Small, deliberately clustered pixel illustrations, shared palette and nearest-neighbour scaling.
const PixelArt=(()=>{
 const P={k:'#000000',d:'#181613',w:'#302820',g:'#45443F',a:'#72736A',b:'#CBBFA2',white:'#F1E6CF',red:'#80382C',r:'#A64D27',o:'#D47A38',y:'#F4B85B',l:'#FFE2A0',green:'#29392D',leaf:'#65745A'};
 function rect(c,x,y,w,h,color){c.fillStyle=P[color]||color;c.fillRect(x,y,w,h)}
 function scene(canvas,frame){const c=canvas.getContext('2d');c.imageSmoothingEnabled=false;rect(c,0,0,320,180,'k');
 // Dark yard, receding fence, stones and a narrow pool of firelight.
 rect(c,59,136,205,44,'d');rect(c,84,150,155,30,'w');rect(c,106,160,110,20,'g');
 for(let x=66;x<265;x+=24){rect(c,x,72,4,69,'d');rect(c,x+1,78,1,50,'w')}rect(c,57,105,209,3,'d');
 [[88,151,18,5],[111,145,19,5],[200,149,25,5],[224,159,13,4],[77,166,15,5]].forEach(([x,y,w,h])=>{rect(c,x,y,w,h,'g');rect(c,x+3,y,w-6,1,'a')});
 // Controlled clusters: stones, joints, ash and paper emerge only near the hearth.
 [[91,128,15,7],[108,124,18,8],[127,120,17,7],[188,122,17,8],[207,128,15,7],[102,139,17,5],[212,140,17,5]].forEach(([x,y,w,h],i)=>{rect(c,x,y,w,h,'g');rect(c,x+2,y+1,w-5,1,'a');rect(c,x+1,y+h-2,w-4,1,'d');if(i%2===0)rect(c,x+w-5,y+2,3,2,'w')});
 [[109,151],[119,162],[201,157],[214,153],[133,169],[189,171],[102,169],[221,168]].forEach(([x,y])=>{rect(c,x,y,4,2,'a');rect(c,x+4,y+2,2,1,'g')});
 rect(c,112,146,13,7,'b');rect(c,114,147,8,1,'w');rect(c,117,149,5,1,'w');rect(c,116,152,7,1,'red');
 rect(c,196,143,14,6,'w');rect(c,199,142,8,2,'g');rect(c,202,144,3,2,'red');
 // Still figure, long arms; the body disappears into true black.
 rect(c,228,75,12,15,'d');rect(c,225,89,18,40,'d');rect(c,220,98,5,38,'d');rect(c,241,98,4,36,'d');rect(c,229,128,5,18,'d');rect(c,238,127,4,17,'d');rect(c,226,90,2,27,'w');rect(c,229,79,2,3,'g');rect(c,235,91,3,10,'w');rect(c,230,103,3,15,'w');rect(c,222,111,2,12,'w');rect(c,231,129,2,8,'g');rect(c,239,130,2,7,'w');
 // Ash and charred logs; colour blocks face the flame.
 [[126,145,48,8],[149,141,42,7],[120,153,41,8],[165,153,41,7]].forEach(([x,y,w,h])=>{rect(c,x,y,w,h,'w');rect(c,x+3,y+1,w-8,2,'g');rect(c,x+8,y,w-16,1,'r')});
 const f=frame%4;rect(c,143,130,38,17,'r');rect(c,149,119-f,25,25,'o');rect(c,155,108+(f%2)*3,10,31,'r');rect(c,159,116+f,9,27,'y');rect(c,152,130,25,12,'y');rect(c,158,129-f,11,12,'l');rect(c,144,138,6,6,'o');rect(c,179,136,6,7,'r');rect(c,147,123+f,3,6,'r');rect(c,172,121+f,3,8,'o');rect(c,154,112+f,2,6,'o');rect(c,164,109+f,3,8,'r');rect(c,170,130,4,3,'l');rect(c,151,102+f,2,3,'o');rect(c,182,111-f,2,2,'r');
 }
 const patterns={wood:['000000000000','0000aa000000','00aabbbaa000','0aabcccbbaa0','abccdddccba0','0abcccccba00','00aabbbba000','000000000000'],paper:['000aaaaaa000','000abbbba000','000abccba000','000abccba000','000abbcba000','000abbbba000','000aaaaaa000','000000000000'],bird:['000000000000','0000aa000000','00aabbaa0000','0aabccbaaa00','abcccbbaaba0','0abbbba00000','000aa0000000','000000000000'],other:['000000000000','0000aa000000','000abbba0000','00abbccba000','00abcbbba000','000abbba0000','0000aa000000','000000000000']};
 function icon(c,tag){let ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;let pattern=tag==='木'?patterns.wood:tag==='紙'?patterns.paper:tag==='生き物'?patterns.bird:patterns.other;const colors={a:P.g,b:P.b,c:P.o,d:P.w};pattern.forEach((row,y)=>[...row].forEach((v,x)=>{if(colors[v]){ctx.fillStyle=colors[v];ctx.fillRect(x*2,y*2+4,2,2)}}))}
 return {scene,icon};
})();
