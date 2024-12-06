var express = require('express');



const Config = require('k8s-config');

const config = new Config({addToEnv: true, optional: false});

config.watch();


const port = config.get('port', 8000);
var ready = false;
var app = express();
app.get('/', function (req, res) {
  var name = config.get('name', 'world');
  res.send(`Hello ${name}!\n`);
});

// Simulate slow startup
app.use('/ready', (request, response) => {
  if (ready){
    return response.sendStatus(200);
  }else{
    return response.sendStatus(500);
  }
});

// Faaaake
app.use('/live', (request, response) => {
  return response.sendStatus(200);
});


app.listen(port, function () {
  console.log(`Serving on port ${port}`);
  setTimeout(function() {
      console.log("Setting ready flag")
      ready = true;
    }, 5000);

});
