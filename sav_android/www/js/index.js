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

  if (!window.console) {
    window.console = {
      log: function() {}
    };
  }

  Storage.prototype.setObject = function(key, value) {
    return this.setItem(key, JSON.stringify(value));
  };

  Storage.prototype.getObject = function(key) {
    var value;
    value = this.getItem(key);
    return value && JSON.parse(value);
  };

  window.str2datePT = function(data) {
    return Date.parse(data.slice(-4) + "-" + data.slice(3, 5) + "-" + data.slice(0, 2));
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
        if (ativ['data'] === formatadata(new Date())) {
          atividades.push(ativ);
        }
      }
      window.localStorage.setObject('atividades', atividades);
      return app.atualizaUI();
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
      return $.post("http://sav.wancharle.com.br/salvar/", {
        'json': JSON.stringify(atividadesPendentes)
      }, function() {
        return console.log('envio ok');
      }, 'json').done(function(data) {
        if (data === true) {
          return Atividade.clearAtividadesPendentes();
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
      if (this.tipo === Atividade.TIPO_AULA) {
        this.identificacao = identificacao;
      } else if (this.tipo === Atividade.TIPO_ALMOCO) {
        this.identificacao = 'Almoço';
      } else if (this.tipo === Atividade.TIPO_EXPEDIENTE) {
        this.identificacao = 'Expediente';
      }
      if (Atividade.estaAberta()) {
        this.load();
      } else {
        data_ativ = new Date();
        this.ativid = this.identificacao;
        this.ativdata = formatadata(data_ativ);
        this.horario_inicio = formatahora(data_ativ);
        this.gps = Expediente.gps;
        this.usuario = Expediente.usuario;
        this.accuracy = Expediente.accuracy;
        this.time = (new Date()).getTime();
        this.save();
      }
      if (this.tipo === Atividade.TIPO_AULA) {
        $("#ativuser").html(this.usuario);
        $("#ativdata").html(this.ativdata + " às " + this.horario_inicio.slice(0, 5) + "h");
        $("#ativgps").html(this.gps);
        $("#ativid").html(this.ativid);
      } else if (this.tipo === Atividade.TIPO_ALMOCO) {
        $("#almouser").html(this.usuario);
        $("#almodata").html(this.ativdata + " às " + this.horario_inicio.slice(0, 5) + "h");
        $("#almogps").html(this.gps);
        $("#almoid").html(this.ativid);
      }
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
      this.storage.setItem('atividade_gps', this.gps);
      this.storage.setItem('atividade_accuracy', this.accuracy);
      return this.storage.setItem('atividade_time', this.time);
    };

    Atividade.prototype.finalizar = function() {
      var bestgps, n_participantes, n_presentes;
      n_presentes = parseInt($('#txtpresentes').val());
      n_participantes = parseInt($('#txtparticipantes').val());
      if (isInteger(n_presentes) && isInteger(n_participantes)) {
        if (n_presentes < n_participantes) {
          alert("O numero de pessoas presentes deve ser igual ou superior ou número de pessoas participantes da atividade!");
          return;
        }
        this.horario_fim = formatahora(new Date());
        this.storage.setItem('atividade_horario_fim', this.horario_fim);
        if (this.gps !== null && Expediente.accuracy > this.accuracy) {
          bestgps = this.gps;
        } else {
          bestgps = Expediente.gps;
        }
        Atividade.armazena('atividade_data', this.usuario, this.tipo, this.ativid, bestgps, this.ativdata, this.horario_inicio, this.horario_fim, n_presentes, n_participantes);
        return $.mobile.changePage('#pgexpediente', {
          changeHash: false
        });
      } else {
        return alert("Para finalizar a atividade é preciso informar o numero de participantes e presentes");
      }
    };

    Atividade.prototype.finalizarAlmoco = function() {
      this.horario_fim = formatahora(new Date());
      this.storage.setItem('atividade_horario_fim', this.horario_fim);
      Atividade.armazena('atividade_data', this.usuario, this.tipo, this.ativid, Expediente.gps, this.ativdata, this.horario_inicio, this.horario_fim);
      return $.mobile.changePage('#pgexpediente', {
        changeHash: false
      });
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
      Expediente.usuario = this.usuario;
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
      if (error.code === error.PERMISSION_DENIED) {
        alert("Para que o sistema funcione por favor ative o GPS do seu telefone");
      }
      if (error.code === error.POSITION_UNAVAILABLE) {
        alert("Não estou conseguindo obter uma posição do GPS, verifique se sua conexão GPS está ativa");
      }
      if (error.code === error.TIMEOUT) {
        return console.log('timeout gps: ' + error.message);
      }
    };

    return Expediente;

  })();

  window.UserView = (function() {
    function UserView() {
      this.submitLogin = __bind(this.submitLogin, this);
      this.storage = window.localStorage;
      this.usuario = this.getUsuario();
      $("#loginForm").on("submit", (function(_this) {
        return function(e) {
          return _this.submitLogin(e);
        };
      })(this));
    }

    UserView.prototype.getUsuario = function() {
      this.usuario = this.storage.getItem('Usuario');
      return this.usuario;
    };

    UserView.prototype.setUsuario = function(usuario) {
      this.usuario = usuario;
      return this.storage.setItem('Usuario', this.usuario);
    };

    UserView.prototype.clear = function() {
      $("#username").val("");
      return $("#password").val("");
    };

    UserView.prototype.trocarUsuario = function() {
      this.storage.removeItem('Usuario');
      this.usuario = null;
      this.clear();
      return $.mobile.changePage('#pglogin', {
        changeHash: false
      });
    };

    UserView.prototype.submitLogin = function(e) {
      var p, u, url;
      $("#submitButton").attr("disabled", "disabled");
      u = $("#username").val();
      p = $("#password").val();
      if (u && p) {
        url = "http://sav.wancharle.com.br/logar/";
        $.post(url, {
          username: u,
          password: p
        }, (function(_this) {
          return function(res) {
            if (res === true) {
              _this.setUsuario(u);
              _this.load();
            } else {
              alert("Usuário ou Senha inválidos!");
            }
            return $("#submitButton").removeAttr("disabled");
          };
        })(this), "json").fail(function() {
          $("#submitButton").removeAttr("disabled");
          return alert('Não foi possivel conectar, verifique sua conexao de dados ou sua rede wifi!');
        });
      } else {
        $("#submitButton").removeAttr("disabled");
      }
      return false;
    };

    UserView.prototype.load = function(gps) {
      if (this.usuario) {
        this.atividadesview = new Atividades();
        this.atividadesview.atualizaUI();
        window.atividadesview = this.atividadesview;
        return $.mobile.changePage("#pglogado", {
          changeHash: false
        });
      } else {
        return $.mobile.changePage("#pglogin", {
          changeHash: false
        });
      }
    };

    return UserView;

  })();

  window.Atividades = (function() {
    function Atividades() {}

    Atividades.prototype.atualizaOntem = function(ativ) {
      var li;
      li = "<li>";
      li += "<h2 data-inset='false'>" + ativ['h_inicio'] + "</h2><div>";
      li += "<p> " + ativ['usuario'] + '@(' + ativ['gps'] + ")</p>";
      li += "<span   style='display:none' class='data'> " + ativ['data'] + '</span>';
      li += "<p> De " + ativ['h_inicio'].slice(0, 5) + "h às " + ativ['h_fim'].slice(0, 5) + "h</p>";
      if (ativ['tipo'] === Atividade.TIPO_AULA) {
        li += "<p> Participantes/Presentes: " + ativ['numero_de_participantes'] + "/" + ativ['numero_de_presentes'] + "</p>";
      }
      return li + "</div></li>";
    };

    Atividades.prototype.atualizaHoje = function(ativ) {
      var li;
      li = "<li data-role='collapsible' data-iconpos='right' data-inset='false'>";
      li += "<h2 data-inset='false'>" + ativ['h_inicio'] + "</h2><div class='ativ" + ativ.id + "'>";
      li += "<p> " + ativ['usuario'] + '@(' + ativ['gps'] + ")</p>";
      li += "<span style='display:none' class='data'> " + ativ['data'] + '</span>';
      li += "<p> De " + ativ['h_inicio'].slice(0, 5) + "h às " + ativ['h_fim'].slice(0, 5) + "h</p>";
      li += '<div class="ui-grid-b"> <div class="ui-block-a"><button class="ui-btn" onclick="atividadesview.start(' + ativ.id + ')">iniciar</button></div> <div class="ui-block-b"> </div> <div class="ui-block-c"><button class="ui-btn" onclick="atividadesview.fim(' + ativ.id + ')">finalizar</button></div> </div>';
      return li + "</div></li>";
    };

    Atividades.prototype.atualizaAmanha = function(ativ) {
      var li;
      li = "<li >";
      li += "<h2 data-inset='false'>" + ativ['h_inicio'] + "</h2><div>";
      li += "<p> " + ativ['usuario'] + '@(' + ativ['gps'] + ")</p>";
      li += "<span  style='display:none' class='data'> " + ativ['data'] + '</span>';
      li += "<p> De " + ativ['h_inicio'].slice(0, 5) + "h às " + ativ['h_fim'].slice(0, 5) + "h</p>";
      if (ativ['tipo'] === Atividade.TIPO_AULA) {
        li += "<p> Participantes/Presentes: " + ativ['numero_de_participantes'] + "/" + ativ['numero_de_presentes'] + "</p>";
      }
      return li + "</div></li>";
    };

    Atividades.prototype.atualizaUI = function() {
      var ativ, atividades, htmlamanha, htmlhoje, htmlontem, now, _i, _len;
      atividades = window.ativtest;
      now = str2datePT(formatadata(new Date()));
      if (atividades) {
        htmlhoje = "";
        htmlontem = "";
        htmlamanha = "";
        for (_i = 0, _len = atividades.length; _i < _len; _i++) {
          ativ = atividades[_i];
          if ((str2datePT(ativ.data) < now) || (ativ.realizada === true)) {
            htmlontem += this.atualizaOntem(ativ);
          } else if (str2datePT(ativ.data) === now) {
            htmlhoje += this.atualizaHoje(ativ);
          } else {
            htmlamanha += this.atualizaAmanha(ativ);
          }
        }
        $('#ulhoje').html(htmlhoje);
        $('#ulontem').html(htmlontem);
        $('#ulamanha').html(htmlamanha);
        $('#ulamanha,#ulontem').listview({
          autodividers: true,
          autodividersSelector: function(li) {
            return $(li).find('.data').text();
          }
        }).listview('refresh');
        return $('#ulhoje').listview().listview('refresh');
      }
    };

    return Atividades;

  })();

  window.App = (function() {
    function App() {
      this.storage = window.localStorage;
      this.userview = null;
      this.bindEvents();
    }

    App.prototype.bindEvents = function() {
      return document.addEventListener('deviceready', this.onDeviceReady, false);
    };

    App.prototype.onDeviceReady = function() {
      return app.main();
    };

    App.prototype.positionSucess = function(gps) {
      return this.userview.load();
    };

    App.prototype.positionError = function(error) {
      return alert('Não foi possível obter sua localização. Verifique as configurações do seu smartphone.');
    };

    App.prototype.main = function() {
      console.log('Received Event: onDeviceReady');
      window.userview = new UserView();
      return userview.load();
    };

    return App;

  })();

  window.ativtest = [
    {
      id: "1",
      usuario: "fabricia",
      realizada: true,
      data: "10/10/2014",
      h_inicio: "07:00",
      h_fim: "07:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "2",
      usuario: "fabricia",
      data: "10/10/2014",
      h_inicio: "08:00",
      h_fim: "08:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "3",
      usuario: "fabricia",
      data: "10/10/2014",
      h_inicio: "09:00",
      h_fim: "09:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "4",
      usuario: "fabricia",
      data: "08/10/2014",
      h_inicio: "07:00",
      h_fim: "07:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "5",
      usuario: "fabricia",
      data: "09/10/2014",
      h_inicio: "08:00",
      h_fim: "08:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "6",
      usuario: "fabricia",
      data: "18/10/2014",
      h_inicio: "09:00",
      h_fim: "09:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "7",
      usuario: "fabricia",
      data: "19/10/2014",
      h_inicio: "07:00",
      h_fim: "07:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }, {
      id: "8",
      usuario: "fabricia",
      data: "19/10/2014",
      h_inicio: "07:00",
      h_fim: "07:30",
      tipo: Atividade.TIPO_AULA,
      numero_de_participantes: 10,
      numero_de_presentes: 11
    }
  ];

}).call(this);
