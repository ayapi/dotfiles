"use strict"

const Lexer = require('pug-lexer').Lexer;
const parse = require('pug-parser');
const walk = require('pug-walk');

function isEscapedText(val) {
  return /^(\'|")/.test(val);
}
function getRawText(escaped) {
  return escaped.replace(/^(\'|")([a-zA-Z0-9_-]+).*$/, '$2');
}

plugin.functionSync('GetIdsAndClassesFromJade', (nvim, args, cb) => {
  const str = args[0];
  const filename = args[1];
  const lexer = new Lexer(str, filename)
  let tokens;
  try {
    tokens = lexer.getTokens();
  } catch (err) {
    debug(err)
    tokens = lexer.tokens
  }
  let ast;
  try {
    ast = parse(JSON.parse(JSON.stringify(tokens)));
  } catch (err) {
    return cb(null, []);
  }
  
  const ids = [];
  const classes = [];
  
  walk(ast, (node, replace) => {
    if (node.type == 'Tag') {
      let attr_ids = [];
      let attr_classes = [];
      
      if (node.attrs) {
        Array.prototype.push.apply(
            ids,
            node.attrs
              .filter((attr) => {
                return attr.name == 'id' && isEscapedText(attr.val);
              })
              .map((attr) => {
                return '#' + getRawText(attr.val);
              })
            );
        
        Array.prototype.push.apply(
            classes,
            node.attrs
              .filter((attr) => {
                return attr.name == 'class' && isEscapedText(attr.val);
              })
              .map((attr) => {
                return '.' + getRawText(attr.val);
              })
            )
      }
      // TODO: walk &attributes({})
      // if (node.attributeBlocks) {
      // 	node.attributeBlocks
      // 		.map((block) => {
      // 			return JSON.parse(block);
      // 		})
      // 		.filter
      // }
    }
  }, {includeDependencies: true});
  cb(null, ids.concat(classes).filter((v, i, self) => { // uniq
    return self.indexOf(v) === i;
  }));
});
