"use strict"

const fs = require('fs');
const html2jade = require('html2jade');

plugin.functionSync('HTML2Jade', (nvim, args, cb) => {
  const html = args[0];
  const opts = args[1];
  html2jade.convertHtml(html, opts, (err, jade) => {
    if (err) {
      debug(err)
      return cb(err);
    }
    cb(null, jade);
  });
});

