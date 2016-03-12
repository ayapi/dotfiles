"use strict"

const detect = require('detect-indent');

plugin.functionSync('ConvertIndent', (nvim, args, cb) => {
  const text = args[0];
  const after_indent = args[1];
  const detected = detect(text);
  
  if (detected.type != 'space' || detected.amount == 0) {
    return cb(null, text);
  }
  
  const converted = text.split(/(\r?\n)/).map((v) => {
    if (/^\r?\n$/.test(v)) {
      return v;
    }
    
    const matched = v.match(/^( +)(.*)$/);
    if (!matched) {
      return v;
    }
    
    const before_indent = detected.indent || '  ';
    return (matched[1]
      .replace(/\t/g, before_indent)
      .replace(new RegExp(before_indent, 'g'), after_indent)
      + matched[2]);
  }).join('');

  cb(null, converted);
});

