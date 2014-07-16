(function() {
  var App;

  App = (function() {
    function App() {
      this.bindEvents();
    }

    App.prototype.bindEvents = function() {
      return document.addEventListener('deviceready', this.onDeviceReady, false);
    };

    App.prototype.onDeviceReady = function() {
      return app.receivedEvent('deviceready');
    };

    App.prototype.receivedEvent = function(id) {
      alert(id);
      return console.log('Received Event: ' + id);
    };

    return App;

  })();

  window.App = App;

}).call(this);
