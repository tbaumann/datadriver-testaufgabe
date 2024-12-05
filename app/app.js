var express = require('express');

const port = 8000;
var app = express();app.get('/', function (req, res) {
  res.send('Hello World!');
});app.listen(port, function () {
  console.log(`Serving on port ${port}`);
});
