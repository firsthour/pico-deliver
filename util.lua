-- pq by pancelor: lexaloffle.com/bbs/?tid=42367
-- this is 90 tokens
function pq(...)printh(qq(...))return...end
function qq(...)local r=""for i=1,select("#",...)do r..=_q(select(i,...),4).." "end return r end
function _q(t,d)if(type(t)~="table"or d<=0)return tostr(t)
local r="{"for k,v in next,t do r..=tostr(k).."=".._q(v,d-1)..","end return r.."}"end