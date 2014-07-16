(function() {
  var App,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  App = (function() {
    function App() {
      this.onDeviceReady = __bind(this.onDeviceReady, this);
      this.bindEvents();
      this.storage = window.localStorage;
      this.usuario = this.getUsuario();
    }

    App.prototype.getUsuario = function() {
      this.usuario = this.storage.getItem('Usuario');
      return this.usuario;
    };

    App.prototype.setUsuario = function(usuario) {
      this.usuario = usuario;
      return this.storage.setItem('Usuario', this.usuario);
    };

    App.prototype.temAtividadesPendentes = function() {
      return false;
    };

    App.prototype.trocarUsuario = function() {
      if (this.temAtividadesPendentes === true) {
        return alert("Existem registros de atividades não enviados aos gerentes. Só é possivel trocar de usuário após enviar todos os registros pendentes.");
      } else {
        this.storage.removeItem('Usuario');
        this.usuario = null;
        return $.mobile.changePage('#pglogin', {
          changeHash: false
        });
      }
    };

    App.prototype.bindEvents = function() {
      return document.addEventListener('deviceready', this.onDeviceReady, false);
    };

    App.prototype.onDeviceReady = function() {
      app.receivedEvent('deviceready');
      return $("#loginForm").on("submit", (function(_this) {
        return function(e) {
          var p, u, url;
          $("#submitButton").attr("disabled", "disabled");
          u = $("#username").val();
          p = $("#password").val();
          if (u && p) {
            url = "http://sav.wancharle.com.br/logar/";
            $.post(url, {
              username: u,
              password: p
            }, function(res) {
              if (res === true) {
                _this.setUsuario(u);
                $.mobile.changePage("#pglogado", {
                  changeHash: false
                });
              } else {
                alert("Usuário ou Senha inválidos!");
              }
              return $("#submitButton").removeAttr("disabled");
            }, "json");
          } else {
            $("#submitButton").removeAttr("disabled");
          }
          return false;
        };
      })(this));
    };

    App.prototype.receivedEvent = function(id) {
      if (this.usuario) {
        $.mobile.changePage("#pglogado", {
          changeHash: false
        });
      }
      return console.log('Received Event: ' + id);
    };

    return App;

  })();

  window.App = App;

}).call(this);
