// edtf@4.11.0 downloaded from https://ga.jspm.io/npm:edtf@4.11.0/index.js

import{D as e,T as t,p as n}from"./_/VHT-xm7x.js";export{B as Bitmask,C as Century,a as Decade,I as Interval,L as List,S as Season,b as Set,Y as Year,d as defaults,f as format}from"./_/VHT-xm7x.js";import"nearley";const r=/^\d{5,}$/;function i(...i){if(!i.length)return new e;if(i.length===1)switch(typeof i[0]){case`object`:return new(t[i[0].type]||e)(i[0]);case`number`:return new e(i[0]);case`string`:if(r.test(i[0]))return new e(Number(i[0]))}let a=n(...i);return new t[a.type](a)}export{e as Date,i as default,n as parse};

