(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.zeroPad = function(num, places) {
    var zero;
    zero = places - num.toString().length + 1;
    return Array(+(zero > 0 && zero)).join("0") + num;
  };

  window.isInteger = function(value) {
    var intRegex;
    intRegex = /^\d+$/;
    return intRegex.test(value);
  };

  Storage.prototype.setObject = function(key, value) {
    return this.setItem(key, JSON.stringify(value));
  };

  Storage.prototype.getObject = function(key) {
    var value;
    value = this.getItem(key);
    return value && JSON.parse(value);
  };

  window.formatadata = function(data) {
    return zeroPad(data.getDate(), 2) + "/" + zeroPad(parseInt(data.getMonth()) + 1, 2) + '/' + data.getFullYear();
  };

  window.formatahora = function(data) {
    return zeroPad(data.getHours(), 2) + ":" + zeroPad(data.getMinutes(), 2) + ':' + zeroPad(data.getSeconds(), 2);
  };

  window.Atividade = (function() {
    Atividade.TIPO_AULA = 'AU';

    Atividade.TIPO_ALMOCO = 'AL';

    Atividade.TIPO_EXPEDIENTE = 'EX';

    Atividade.estaAberta = function() {
      var expdata;
      expdata = window.localStorage.getItem('atividade_data');
      if (expdata) {
        return true;
      } else {
        return false;
      }
    };

    Atividade.armazena = function(id_de_remocao, usuario, tipo, identificacao, gps, ativdata, horario_inicio, horario_fim, numero_de_presentes, numero_de_participantes) {
      var atividade, atividades;
      atividades = window.localStorage.getObject('atividades');
      if (!atividades) {
        atividades = new Array();
      }
      atividade = {
        'usuario': usuario,
        'id': identificacao,
        'tipo': tipo,
        'data': ativdata,
        'h_inicio': horario_inicio,
        'h_fim': horario_fim,
        'gps': gps,
        'pendente': true,
        'time': (new Date()).getTime(),
        'numero_de_presentes': numero_de_presentes,
        'numero_de_participantes': numero_de_participantes
      };
      atividades.push(atividade);
      window.localStorage.setObject('atividades', atividades);
      window.localStorage.removeItem(id_de_remocao);
      return Atividade.envia();
    };

    Atividade.clearAtividadesPendentes = function() {
      var ativ, atividades, _i, _len, _ref;
      atividades = new Array();
      _ref = window.localStorage.getObject('atividades');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        ativ = _ref[_i];
        if (ativ['pendente']) {
          ativ['pendente'] = false;
        }
        atividades.push(ativ);
      }
      return window.localStorage.setObject('atividades', atividades);
    };

    Atividade.getAtividadesPendentes = function() {
      var ativ, atividades, atividadesPendentes, _i, _len;
      atividadesPendentes = new Array();
      atividades = window.localStorage.getObject('atividades');
      if (!atividades) {
        return null;
      }
      for (_i = 0, _len = atividades.length; _i < _len; _i++) {
        ativ = atividades[_i];
        if (ativ['pendente']) {
          atividadesPendentes.push(ativ);
        }
      }
      return atividadesPendentes;
    };

    Atividade.envia = function() {
      var atividadesPendentes;
      atividadesPendentes = Atividade.getAtividadesPendentes();
      return $.ajax({
        url: "http://sav.wancharle.com.br/registra_atividades/",
        type: 'POST',
        contentType: 'application/json',
        data: {
          json: JSON.stringify(atividadesPendentes)
        },
        dataType: 'json'
      }).done(function(data) {
        if (data === true) {
          return window.localStorage.removeItem('atividadesPendentes');
        }
      }).fail(function(error, textstatus) {
        alert('Não foi possível enviar os dados registrados ao servidor. Isso ocorre provavelmente por falta de conexão de dados no momento. Tente novamente quando tver um conexão de internet estável');
        return console.log(textstatus);
      });
    };

    function Atividade(tipo, identificacao) {
      var data_ativ;
      this.tipo = tipo;
      this.storage = window.localStorage;
      if (this.tipo === 'AU') {
        this.identificacao = identificacao;
      } else if (this.tipo === 'AL') {
        this.identificacao = 'Almoço';
      } else if (this.tipo === 'EX') {
        this.identificacao = 'Expediente';
      }
      if (Atividade.estaAberta()) {
        this.load();
      } else {
        data_ativ = new Date();
        this.ativid = identificacao;
        this.ativdata = formatadata(data_ativ);
        this.horario_inicio = formatahora(data_ativ);
        this.gps = Expediente.gps;
        this.usuario = Expediente.usuario;
        this.accuracy = Expediente.accuracy;
        this.time = (new Date()).getTime();
        this.save();
      }
      $("#ativuser").html(this.usuario);
      $("#ativdata").html(this.ativdata + " às " + this.horario_inicio.slice(0, 5) + "h");
      $("#ativgps").html(this.gps);
      $("#ativid").html(this.ativid);
    }

    Atividade.prototype.load = function() {
      this.tipo = this.storage.getItem('ativtipo');
      this.ativdata = this.storage.getItem('atividade_data');
      this.ativid = this.storage.getItem('ativid');
      this.horario_inicio = this.storage.getItem('atividade_horario_inicio');
      this.gps = this.storage.getItem('atividade_gps');
      this.accuracy = this.storage.getItem('atividade_accuracy');
      this.usuario = this.storage.getItem('atividade_usuario');
      this.time = parseInt(this.storage.getItem('atividade_time'));
      return this.expdata;
    };

    Atividade.prototype.save = function() {
      this.storage.setItem('ativtipo', this.tipo);
      this.storage.setItem('ativid', this.ativid);
      this.storage.setItem('atividade_data', this.ativdata);
      this.storage.setItem('atividade_usuario', this.usuario);
      this.storage.setItem('atividade_horario_inicio', this.horario_inicio);
      this.storage.setItem('atividade_horario_gps', this.gps);
      this.storage.setItem('atividade_accuracy', this.accuracy);
      return this.storage.setItem('atividade_time', this.time);
    };

    Atividade.prototype.finalizar = function() {
      var n_participantes, n_presentes;
      n_presentes = $('#txtpresentes').val();
      n_participantes = $('#txtparticipantes').val();
      if (isInteger(n_presentes) && isInteger(n_participantes)) {
        if (n_presentes < n_participantes) {
          alert("O numero de pessoas presentes deve ser igual ou superior ou número de pessoas participantes da atividade!");
          return;
        }
        this.horario_fim = formatahora(new Date());
        this.storage.setItem('atividade_horario_fim', this.horario_fim);
        Atividade.armazena('atividade_data', this.usuario, this.tipo, this.ativid, Expediente.gps, this.ativdata, this.horario_inicio, this.horario_fim, n_presentes, n_participantes);
        return $.mobile.changePage('#pglogado', {
          changeHash: false
        });
      } else {
        return alert("Para finalizar a atividade é preciso informar o numero de participantes e presentes");
      }
    };

    return Atividade;

  })();

  window.Expediente = (function() {
    Expediente.tipo = "EX";

    Expediente.gps = null;

    Expediente.usuario = null;

    Expediente.accuracy = 1000;

    Expediente.estaAberto = function() {
      var expdata;
      expdata = window.localStorage.getItem('expediente_data');
      if (expdata) {
        return true;
      } else {
        return false;
      }
    };

    function Expediente(usuario) {
      var expdata;
      this.usuario = usuario;
      this.iniciaWatch = __bind(this.iniciaWatch, this);
      this.storage = window.localStorage;
      expdata = this.load();
      if (!expdata) {
        expdata = new Date();
        this.expdata = formatadata(expdata);
        this.horario_inicio = formatahora(expdata);
        this.save();
      }
      Expediente.accuracy = 1000;
      this.iniciaWatch();
      $("#expuser").html(this.usuario);
      $("#expdata").html(this.expdata + " às " + this.horario_inicio.slice(0, 5) + "h");
    }

    Expediente.prototype.load = function() {
      if (Expediente.estaAberto()) {
        this.expdata = this.storage.getItem('expediente_data');
        this.horario_inicio = this.storage.getItem('expediente_horario_inicio');
        Expediente.gps = this.storage.getItem('expediente_gps');
        Expediente.accuracy = this.storage.getItem('expediente_accuracy');
        return this.expdata;
      } else {
        return null;
      }
    };

    Expediente.prototype.save = function() {
      this.storage.setItem('expediente_data', this.expdata);
      this.storage.setItem('expediente_horario_inicio', this.horario_inicio);
      this.storage.setItem('expediente_gps', Expediente.gps);
      return this.storage.setItem('expediente_accuracy', Expediente.accuracy);
    };

    Expediente.prototype.finalizar = function() {
      this.horario_fim = formatahora(new Date());
      this.storage.setItem('expediente_horario_fim', this.horario_fim);
      Atividade.armazena('expediente_data', this.usuario, Atividade.TIPO_EXPEDIENTE, 'Expediente', Expediente.gps, this.expdata, this.horario_inicio, this.horario_fim);
      return $.mobile.changePage('#pglogado', {
        changeHash: false
      });
    };

    Expediente.prototype.iniciaWatch = function() {
      return this.watchid = navigator.geolocation.watchPosition((function(_this) {
        return function(position) {
          return _this.watchSucess(position);
        };
      })(this), (function(_this) {
        return function(error) {
          return _this.watchError(error);
        };
      })(this), {
        enableHighAccuracy: true,
        timeout: 1 * 60 * 1000
      });
    };

    Expediente.prototype.watchSucess = function(position) {
      if (Expediente.accuracy > position.coords.accuracy) {
        Expediente.gps = position.coords.latitude + ", " + position.coords.longitude;
        Expediente.accuracy = position.coords.accuracy;
        return console.log("latlong: " + Expediente.gps + " accuracy:" + position.coords.accuracy);
      }
    };

    Expediente.prototype.watchError = function(error) {
      if (error.code === navigator.geolocation.PositionError.PERMISSION_DENIED) {
        alert("Para que o sistema funcione por favor ative o GPS do seu telefone");
      }
      if (error.code === navigator.geolocation.PositionError.POSITION_UNAVAILABLE) {
        alert("Não estou conseguindo obter uma posição do GPS, verifique se sua conexão GPS está ativa");
      }
      if (error.code === navigator.geolocation.PositionError.TIMEOUT) {
        return console.log('timeout gps: ' + error.message);
      }
    };

    return Expediente;

  })();

  window.App = (function() {
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

    App.prototype.iniciarExpediente = function() {
      this.expediente = new Expediente(this.usuario);
      return $.mobile.changePage("#pgexpediente", {
        changeHash: false
      });
    };

    App.prototype.iniciarAtividade = function() {
      var identificacao;
      identificacao = window.prompt('Informe a turma/identificação da atividade');
      if (identificacao) {
        this.atividade = new Atividade(Atividade.TIPO_AULA, identificacao);
        return $.mobile.changePage('#pgatividade', {
          changeHash: false
        });
      }
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

    App.prototype.atualizaUI = function() {
      var ativ, atividades, atividadesPendentes, html, li, _i, _len;
      atividadesPendentes = Atividade.getAtividadesPendentes();
      if (atividadesPendentes) {
        html = "Histórico de Atividades <span class='ui-li-count'>" + atividadesPendentes.length + "</span>";
        $('#logativrecent').html(html);
        $('#logulop').listview().listview('refresh');
      }
      atividades = window.localStorage.getObject('atividades');
      if (atividades) {
        html = "";
        for (_i = 0, _len = atividades.length; _i < _len; _i++) {
          ativ = atividades[_i];
          li = "<li>";
          li += "<h2>" + ativ['id'] + "</h2>";
          li += "<p class='ui-li-aside'>" + ativ['data'] + "</p>";
          li += "<p> De " + ativ['h_inicio'].slice(0, 5) + "h a " + ativ['h_fim'].slice(0, 5) + "h</p>";
          li += "<p> Em: " + ativ["gps"] + "</p>";
          html += li;
        }
        $('#ulhistorico').html(html);
        return $('#ulhistorico').listview().listview('refresh');
      }
    };

    App.prototype.mostraHistorico = function() {
      this.atualizaUI();
      return $.mobile.changePage("#pghistorico", {
        changeHash: false
      });
    };

    App.prototype.receivedEvent = function(id) {
      if (this.usuario) {
        this.atualizaUI();
        if (Expediente.estaAberto()) {
          this.expediente = new Expediente(this.usuario);
          $.mobile.changePage("#pgexpediente", {
            changeHash: false
          });
        } else {
          $.mobile.changePage("#pglogado", {
            changeHash: false
          });
        }
      }
      return console.log('Received Event: ' + id);
    };

    return App;

  })();

}).call(this);
