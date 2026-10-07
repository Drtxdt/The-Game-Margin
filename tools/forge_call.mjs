import { Client } from './godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from './godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';
import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve(import.meta.dirname,'..');
const requestFile = process.argv[2];
const requests = requestFile ? JSON.parse(fs.readFileSync(requestFile,'utf8').replace(/^\uFEFF/,'')) : [];
const transport = new StdioClientTransport({command:'D:/nodejs/node.exe',args:[path.join(root,'tools/godot-forge/dist/index.js'),'--project',root,'--godot','D:/Godot_v4.7.2/Godot_v4.7.2-stable_win64.exe','--launch','none'],stderr:'inherit',env:{...process.env,GODOT_PATH:'D:/Godot_v4.7.2/Godot_v4.7.2-stable_win64.exe'}});
const client = new Client({name:'margin-validation',version:'1.0'});
fs.mkdirSync(path.join(root,'tests/output'),{recursive:true});
try {
 await client.connect(transport);
 if(!requests.length) {const list=await client.listTools(); fs.writeFileSync(path.join(root,'tests/output/forge-tools.json'),JSON.stringify(list,null,2));console.log(list.tools.map(t=>({name:t.name,description:t.description.slice(0,160)})));}
 for(let i=0;i<requests.length;i++) {
  const [name,args,label]=requests[i];
  const result=await client.callTool({name,arguments:args},undefined,{timeout:180000});
  const readable=[];
  for (const item of result.content??[]) {
   if(item.type==='image') {const file=path.join(root,'tests/output',(label||`${name}-${i}`)+'.png');fs.writeFileSync(file,Buffer.from(item.data,'base64'));readable.push({image:file});}
   else if(item.type==='text') readable.push(item.text);
  }
  const output={tool:name,args,isError:!!result.isError,result:readable};
  fs.writeFileSync(path.join(root,'tests/output',(label||`${name}-${i}`)+'.json'),JSON.stringify(output,null,2));
  console.log(JSON.stringify(output).slice(0,18000));
 }
} finally {await client.close();}
