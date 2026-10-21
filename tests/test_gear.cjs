const fs = require('fs');
const path = require('path');
const assert = require('assert');
const dep = name => require(name);
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = dep('fengari');
const parser = dep('luaparse');
const root = path.resolve(__dirname,'..');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function run(source) {
  if (lauxlib.luaL_dostring(L,to_luastring(source)) !== lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L,-1)));
}
const test = fs.readFileSync(path.join(__dirname,'test_gear.lua'),'utf8').split('-- LOAD ADDON HERE');
run(test[0]);
const toc = fs.readFileSync(path.join(root,'GearFinder/GearFinder.toc'),'utf8').split(/\r?\n/).filter(s=>s&&!s.startsWith('#'));
for (const name of toc) {
  const file=path.join(root,'GearFinder',name);
  assert(fs.existsSync(file),name);
  const src=fs.readFileSync(file,'utf8');
  parser.parse(src,{luaVersion:'5.1'});
  run('assert(load([====['+src+']====]))("GearFinder",G)');
}
run(test[1]);
console.log('PASS: Lua 5.1 syntax, data integrity, armor, faction and acquisition filters, 29 profiles, ranking, level previews, party-chat drafts, source lookup, inspect response handling, native Inspect controls, and UI interactions.');
