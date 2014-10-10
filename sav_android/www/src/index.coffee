# vim: set ts=2 sw=2 sts=2 expandtab:

window.zeroPad= (num, places) ->
    zero = places - num.toString().length + 1
    return Array(+(zero > 0 && zero)).join("0") + num
window.isInteger = (value)->
    intRegex = /^\d+$/
    return intRegex.test(value)

# fix para console.log em browsers antigos
if (not window.console)
    window.console = {log: () ->  }

  
Storage.prototype.setObject = (key, value) ->
        this.setItem(key, JSON.stringify(value))


Storage.prototype.getObject = (key) ->
        value = this.getItem(key)
        return value and JSON.parse(value)

window.str2datePT = (data)->
    return Date.parse(data.slice(-4)+"-"+data.slice(3,5)+"-"+data.slice(0,2))

window.formatadata = (data) ->
    return zeroPad(data.getDate(),2)+"/"+zeroPad(parseInt(data.getMonth())+1,2)+'/'+data.getFullYear()


window.formatahora = (data) ->
    return zeroPad(data.getHours(),2)+":"+zeroPad(data.getMinutes(),2)+':'+zeroPad(data.getSeconds(),2)

class window.Atividade
    @TIPO_AULA = 'AU' 
    @TIPO_ALMOCO = 'AL'
    @TIPO_EXPEDIENTE = 'EX'

    @estaAberta: ->
        expdata = window.localStorage.getItem('atividade_data')
        if expdata
            return true
        else
            return false
  
    @armazena: (id_de_remocao, usuario, tipo, identificacao,gps, ativdata, horario_inicio, horario_fim, numero_de_presentes, numero_de_participantes) ->
        atividades = window.localStorage.getObject('atividades')
        if not atividades
            atividades = new Array()

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
            }
        atividades.push(atividade)
        window.localStorage.setObject('atividades',atividades)
        window.localStorage.removeItem(id_de_remocao)
        Atividade.envia()

    @clearAtividadesPendentes: ()->
        atividades = new Array()
        for ativ in window.localStorage.getObject('atividades')
            if ativ['pendente']
                ativ['pendente']=false
            if ativ['data'] == formatadata(new Date())
                atividades.push(ativ)
        window.localStorage.setObject('atividades',atividades)
        app.atualizaUI()
        
    @getAtividadesPendentes: () ->
        atividadesPendentes = new Array()
        atividades = window.localStorage.getObject('atividades')
        if not atividades
            return null
        for ativ in   atividades
            if ativ['pendente']
                atividadesPendentes.push(ativ)
        return atividadesPendentes

    @envia: () ->

        atividadesPendentes = Atividade.getAtividadesPendentes() 
        $.post( "http://sav.wancharle.com.br/salvar/", {'json':JSON.stringify(atividadesPendentes)}, 
            ()-> 
                console.log('envio ok')
            ,'json')
        .done((data)->
            if data == true

                Atividade.clearAtividadesPendentes()
        ).fail((error,textstatus)->
            alert('Não foi possível enviar os dados registrados ao servidor. Isso ocorre provavelmente por falta de conexão de dados no momento. Tente novamente quando tver um conexão de internet estável')
            console.log(textstatus)
        )
         

    
    constructor: (@tipo, identificacao ) ->
        @storage = window.localStorage
        if @tipo == Atividade.TIPO_AULA
           @identificacao = identificacao
        else if @tipo == Atividade.TIPO_ALMOCO
           @identificacao = 'Almoço'
        else if @tipo == Atividade.TIPO_EXPEDIENTE
           @identificacao = 'Expediente'
   
        if Atividade.estaAberta()
            @load()
        else
            data_ativ = new Date()
            @ativid = @identificacao
            @ativdata= formatadata(data_ativ)
            @horario_inicio = formatahora(data_ativ)
            @gps = Expediente.gps
            @usuario = Expediente.usuario
            @accuracy = Expediente.accuracy
            @time = (new Date()).getTime()
            @save()
 
        if @tipo == Atividade.TIPO_AULA
            $("#ativuser").html(@usuario)
            $("#ativdata").html(@ativdata + " às "+ @horario_inicio.slice(0,5)+"h")
            $("#ativgps").html(@gps) 
            $("#ativid").html(@ativid)
        else if @tipo ==Atividade.TIPO_ALMOCO
            $("#almouser").html(@usuario)
            $("#almodata").html(@ativdata + " às "+ @horario_inicio.slice(0,5)+"h")
            $("#almogps").html(@gps) 
            $("#almoid").html(@ativid)
        
            
    load: () ->
         @tipo= @storage.getItem('ativtipo')
         @ativdata = @storage.getItem('atividade_data')
         @ativid = @storage.getItem('ativid')
         @horario_inicio = @storage.getItem('atividade_horario_inicio')
         @gps = @storage.getItem('atividade_gps')
         @accuracy = @storage.getItem('atividade_accuracy')
         @usuario = @storage.getItem('atividade_usuario')
         @time =parseInt( @storage.getItem('atividade_time'))
         return @expdata

    save: () ->
        @storage.setItem('ativtipo',@tipo)
        @storage.setItem('ativid',@ativid)
        @storage.setItem('atividade_data',@ativdata)
        @storage.setItem('atividade_usuario',@usuario)
        @storage.setItem('atividade_horario_inicio',@horario_inicio)
        @storage.setItem('atividade_gps',@gps)
        @storage.setItem('atividade_accuracy',@accuracy)
        @storage.setItem('atividade_time',@time)

    finalizar: ()->
        n_presentes = parseInt($('#txtpresentes').val())
        n_participantes = parseInt($('#txtparticipantes').val())
        if isInteger(n_presentes) and isInteger(n_participantes)
            if n_presentes < n_participantes
                alert("O numero de pessoas presentes deve ser igual ou superior ou número de pessoas participantes da atividade!")
                return

            @horario_fim = formatahora(new Date())
            @storage.setItem('atividade_horario_fim',@horario_fim)
            if @gps != null and Expediente.accuracy > @accuracy
                bestgps = @gps
            else
                bestgps = Expediente.gps


            Atividade.armazena('atividade_data',
               @usuario,
               @tipo,
               @ativid,
               bestgps, # TODO:melhorar
               @ativdata,
               @horario_inicio,
               @horario_fim,
               n_presentes,
               n_participantes,
            )
            $.mobile.changePage('#pgexpediente',{changeHash:false})
        else
            alert("Para finalizar a atividade é preciso informar o numero de participantes e presentes")
    finalizarAlmoco: ()->
        @horario_fim = formatahora(new Date())
        @storage.setItem('atividade_horario_fim',@horario_fim)

        Atividade.armazena('atividade_data',
           @usuario,
           @tipo,
           @ativid,
           Expediente.gps, # TODO:melhorar
           @ativdata,
           @horario_inicio,
           @horario_fim,
        )
        $.mobile.changePage('#pgexpediente',{changeHash:false})






class window.Expediente
    @tipo = "EX"
    @gps = null 
    @usuario = null
    @accuracy = 1000
    @estaAberto: ->
         expdata = window.localStorage.getItem('expediente_data')
         if expdata
            return true
         else
            return false

    constructor: (@usuario) ->
        @storage = window.localStorage
        expdata = @load()
        if not expdata
            expdata = new Date()
            @expdata = formatadata(expdata)
            @horario_inicio = formatahora(expdata)
            @save()
        Expediente.accuracy = 1000
        @iniciaWatch()
        
        Expediente.usuario = @usuario

        $("#expuser").html(@usuario)
        $("#expdata").html(@expdata + " às "+ @horario_inicio.slice(0,5)+"h")
       
    
    load: ()-> 
        if Expediente.estaAberto()
            @expdata = @storage.getItem('expediente_data')
            @horario_inicio = @storage.getItem('expediente_horario_inicio')
            Expediente.gps = @storage.getItem('expediente_gps')
            Expediente.accuracy = @storage.getItem('expediente_accuracy')
            return @expdata
        else
            return null

    save: ()->
        @storage.setItem('expediente_data',@expdata)
        @storage.setItem('expediente_horario_inicio',@horario_inicio)
        @storage.setItem('expediente_gps',Expediente.gps)
        @storage.setItem('expediente_accuracy',Expediente.accuracy)

    finalizar: ()->
        @horario_fim = formatahora(new Date())
        @storage.setItem('expediente_horario_fim',@horario_fim)

        Atividade.armazena('expediente_data',
           @usuario,
           Atividade.TIPO_EXPEDIENTE,
           'Expediente',
           Expediente.gps,
           @expdata,
           @horario_inicio,
           @horario_fim,
        )
        
        $.mobile.changePage('#pglogado',{changeHash:false})
        


    iniciaWatch: () =>
         @watchid = navigator.geolocation.watchPosition(
            (position) =>
                @watchSucess(position)
            ,(error) =>
                @watchError(error)
            ,{
                enableHighAccuracy: true
                timeout: 1*60*1000
            }
         )
    watchSucess: (position) ->
        if Expediente.accuracy > position.coords.accuracy
            Expediente.gps = position.coords.latitude+", "+position.coords.longitude   
            Expediente.accuracy = position.coords.accuracy 
            console.log("latlong: "+Expediente.gps + " accuracy:"+position.coords.accuracy)

    watchError: (error) ->
        if error.code == error.PERMISSION_DENIED
           alert("Para que o sistema funcione por favor ative o GPS do seu telefone")

        if error.code == error.POSITION_UNAVAILABLE
           alert("Não estou conseguindo obter uma posição do GPS, verifique se sua conexão GPS está ativa")

        if error.code == error.TIMEOUT
           console.log('timeout gps: ' + error.message)

class window.UserView
  constructor: ->
    @storage = window.localStorage
    @usuario = this.getUsuario()
    $("#loginForm").on("submit", (e) => @submitLogin(e) )

  getUsuario: () ->
    @usuario = @storage.getItem('Usuario')
    return @usuario
  
  setUsuario: (usuario)->
    @usuario =  usuario
    @storage.setItem('Usuario',@usuario)
  
  clear: () ->
    $("#username").val("")
    $("#password").val("")

  trocarUsuario: () ->
    @storage.removeItem('Usuario')
    @usuario = null
    @clear()
    $.mobile.changePage('#pglogin',{changeHash:false})

  submitLogin: (e) =>
    #disable the button so we can't resubmit while we wait
    $("#submitButton").attr("disabled","disabled")
    u = $("#username").val()
    p = $("#password").val()
    if (u and  p)
      url = "http://sav.wancharle.com.br/logar/"
      $.post(url, {username:u,password:p}, (res) =>
            
        if(res == true)
          @setUsuario u
          @load()
        else
          alert("Usuário ou Senha inválidos!")
        
        $("#submitButton").removeAttr("disabled")

      ,"json").fail(() ->
         $("#submitButton").removeAttr("disabled")
         alert('Não foi possivel conectar, verifique sua conexao de dados ou sua rede wifi!')

        )
    else
        $("#submitButton").removeAttr("disabled")
    return false

  load: (gps) ->
    if @usuario 
      @atividadesview = new Atividades()
      @atividadesview.atualizaUI()
      window.atividadesview = @atividadesview

      $.mobile.changePage("#pglogado",{changeHash:false})                    
    else
      $.mobile.changePage("#pglogin",{changeHash:false})


class window.Atividades
  atualizaOntem: (ativ) ->
    li = "<li>"
    li+="<h2 data-inset='false'>"+ativ['h_inicio']+"</h2><div>"
    li+="<p> "+ativ['usuario']+ '@(' + ativ['gps']+ ")</p>"
    li+="<span   style='display:none' class='data'> "+ativ['data']+ '</span>'
    li+="<p> De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    if ativ['tipo'] == Atividade.TIPO_AULA
        li+="<p> Participantes/Presentes: "+ ativ['numero_de_participantes'] + "/" + ativ['numero_de_presentes'] + "</p>"
    return li+"</div></li>"

  atualizaHoje: (ativ) ->
    li = "<li data-role='collapsible' data-iconpos='right' data-inset='false'>"
    li+="<h2 data-inset='false'>"+ativ['h_inicio']+"</h2><div class='ativ"+ativ.id+"'>"
    li+="<p> "+ativ['usuario']+ '@(' + ativ['gps']+ ")</p>"
    li+="<span style='display:none' class='data'> "+ativ['data']+ '</span>'
    li+="<p> De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    li+='<div class="ui-grid-b">
    <div class="ui-block-a"><button class="ui-btn" onclick="atividadesview.start('+ativ.id+')">iniciar</button></div>
    <div class="ui-block-b"> </div>
    <div class="ui-block-c"><button class="ui-btn" onclick="atividadesview.fim('+ativ.id+')">finalizar</button></div>
</div>'
    return li+"</div></li>"


  atualizaAmanha: (ativ) ->
    li = "<li >"
    li+="<h2 data-inset='false'>"+ativ['h_inicio']+"</h2><div>"
    li+="<p> "+ativ['usuario']+ '@(' + ativ['gps']+ ")</p>"
    li+="<span  style='display:none' class='data'> "+ativ['data']+ '</span>'
    li+="<p> De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    if ativ['tipo'] == Atividade.TIPO_AULA
        li+="<p> Participantes/Presentes: "+ ativ['numero_de_participantes'] + "/" + ativ['numero_de_presentes'] + "</p>"
    return li+"</div></li>"

  atualizaUI: ()->
      #atividades = window.localStorage.getObject('atividades')
      atividades = window.ativtest
      now = str2datePT(formatadata(new Date()))
      if atividades
          htmlhoje = ""
          htmlontem = ""
          htmlamanha = ""
          for ativ in atividades
            if (str2datePT(ativ.data)< now) or (ativ.realizada==true)
              htmlontem += @atualizaOntem(ativ)
            else if str2datePT(ativ.data) == now
              htmlhoje += @atualizaHoje(ativ)
            else
              htmlamanha += @atualizaAmanha(ativ)

          $('#ulhoje').html(htmlhoje)
          $('#ulontem').html(htmlontem)
          $('#ulamanha').html(htmlamanha)
          $('#ulamanha,#ulontem').listview({ 
            autodividers:true,
            autodividersSelector:  ( li ) ->
                  return $(li).find('.data').text();
          }).listview('refresh')

          $('#ulhoje').listview().listview('refresh')
      
      

class window.App
    # Application Constructor
    constructor: () ->
        @storage = window.localStorage
        @userview = null
        this.bindEvents()
          
    bindEvents: () ->
        document.addEventListener('deviceready', this.onDeviceReady, false)

    
    onDeviceReady: () ->
        app.main()
               
    positionSucess: (gps) ->
        @userview.load()

    positionError: (error) ->
        alert('Não foi possível obter sua localização. Verifique as configurações do seu smartphone.') 

    main: () ->
        console.log('Received Event: onDeviceReady' )       
        window.userview=new UserView()
        userview.load()

window.ativtest = [
  { id:"1", usuario:"fabricia",realizada:true, data:"10/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"2", usuario:"fabricia", data:"10/10/2014", h_inicio: "08:00", h_fim: "08:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"3", usuario:"fabricia", data:"10/10/2014", h_inicio: "09:00", h_fim: "09:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"4", usuario:"fabricia", data:"08/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"5", usuario:"fabricia", data:"09/10/2014", h_inicio: "08:00", h_fim: "08:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"6", usuario:"fabricia", data:"18/10/2014", h_inicio: "09:00", h_fim: "09:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"7", usuario:"fabricia", data:"19/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  { id:"8", usuario:"fabricia", data:"19/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA, numero_de_participantes: 10, numero_de_presentes:11 },
  ]
