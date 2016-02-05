"use strict"

const detect = require('detect-indent');

plugin.functionSync('ConvertIndent', (nvim, args, cb) => {
  const text = args[0];
  const detected = detect(text);
  
  if (detected.type != 'space' || detected.amount == 0) {
    return cb(null, text);
  }
  
  const tabbed = text.split(/(\r?\n)/).map((v) => {
    if (/^\r?\n$/.test(v)) {
      return v;
    }
    
    const matched = v.match(/^( +)(.*)$/);
    if (!matched) {
      return v;
    }
    
    const indent = detected.indent || '  ';
    return (matched[1]
      .replace(/\t/g, indent)
      .replace(new RegExp(indent, 'g'), '\t')
      .replace(' ', '')
      + matched[2]);
  }).join('');

  cb(null, tabbed);
});

