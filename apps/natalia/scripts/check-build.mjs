import {readFileSync,readdirSync,statSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const dist=fileURLToPath(new URL('../dist/',import.meta.url));
const html=readFileSync(dist+'index.html','utf8');
const scripts=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].reduce((n,match)=>n+Buffer.byteLength(match[1]),0);
const javascriptBytes=scripts+readdirSync(dist+'_astro').filter(name=>name.endsWith('.js')).reduce((n,name)=>n+statSync(dist+'_astro/'+name).size,0);
const cssFiles=readdirSync(dist+'_astro').filter(name=>name.endsWith('.css'));
const css=cssFiles.map(name=>readFileSync(dist+'_astro/'+name,'utf8')).join('\n');
// Full reference content and native dialog readers are server-rendered, with no framework hydration.
assert(Buffer.byteLength(html)<=90000,'Complete public HTML exceeded 90 KB.');
assert(javascriptBytes<=8192,'Initial JavaScript exceeded 8 KB.');
assert(Buffer.byteLength(css)<=50000,'Complete public stylesheet exceeded 50 KB.');
assert(!/<iframe\b|<script\b[^>]*src=["'][^"']*embed-v1/i.test(html),'Booking loaded before patient intent.');
assert(!/fonts\.googleapis\.com|fonts\.gstatic\.com/.test(html+css),'A third-party font request was introduced.');
for(const file of readdirSync(dist+'images')) assert(statSync(dist+'images/'+file).size<=100000,'A responsive photo exceeded 100 KB: '+file);
const fontBytes=readdirSync(dist+'fonts').filter(name=>name.endsWith('.woff2')).reduce((n,name)=>n+statSync(dist+'fonts/'+name).size,0);
assert(fontBytes<=180000,'Fonts exceeded 180 KB.');
console.log(JSON.stringify({htmlBytes:Buffer.byteLength(html),javascriptBytes,cssBytes:Buffer.byteLength(css),fontBytes,initialWidget:false}));
