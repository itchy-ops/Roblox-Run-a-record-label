const fs = require('node:fs');
const path = require('node:path');
const lua = require('luaparse');
let count = 0;
function scan(dir) {
  for (const name of fs.readdirSync(dir)) {
    const file = path.join(dir, name);
    if (fs.statSync(file).isDirectory()) scan(file);
    else if (name.endsWith('.lua')) {
      lua.parse(fs.readFileSync(file, 'utf8'), {luaVersion: '5.3'});
      count++;
    }
  }
}
scan('src');
console.log(`Parsed ${count} game scripts successfully`);
