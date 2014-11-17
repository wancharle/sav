# vim: set ts=2 sw=2 sts=2 expandtab:

window.zeroPad= (num, places) ->
    zero = places - num.toString().length + 1
    return Array(+(zero > 0 && zero)).join("0") + num
window.isInteger = (value)->
    intRegex = /^\d+$/
    return intRegex.test(value)

window.getIntVazio = (value)->
  if value
      return parseInt(value)
  else
      return ""
# fix para console.log em browsers antigos
if (not window.console)
    window.console = {log: () ->  }

  
Storage.prototype.setObject = (key, value) ->
        this.setItem(key, JSON.stringify(value))


Storage.prototype.getObject = (key) ->
        value = this.getItem(key)
        return value and JSON.parse(value)

window.str2datePT = (data)->
    #return Date.parse(data.slice(-4)+"-"+data.slice(3,5)+"-"+data.slice(0,2))
    return new Date(parseInt(data.slice(-4)),parseInt(data.slice(3,5)) - 1,parseInt(data.slice(0,2))).getTime()

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






class window.GPSControle
    @gps = null 
    @time = 0
    @accuracy = 1000

    @estaAberto: ->
         gpsdata = window.localStorage.getItem('gps_data')
         if gpsdata
            return true
         else
            return false

    constructor: () ->
        @storage = window.localStorage
        GPSControle.accuracy = 1000
        @load()
        @iniciaWatch()
        @mostraGPS()
       
    mostraGPS:()->
        $("#barrastatus p.gps").html(GPSControle.gps+"<br>("+parseInt(GPSControle.accuracy)+" metros)")

    load: ()-> 
        if GPSControle.estaAberto()
            GPSControle.gps = @storage.getItem('gps_data')
            GPSControle.accuracy = @storage.getItem('gps_accuracy')
            GPSControle.time = @storage.getItem('gps_time')
            @mostraGPS()
            return true
        else
            return null

    save: ()->
      @storage.setItem('gps_data',GPSControle.gps)
      @storage.setItem('gps_time',GPSControle.time)
      @storage.setItem('gps_accuracy',GPSControle.accuracy)

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
        $("#barrastatus p.hora").html(formatahora(new Date()).slice(0,5)+"h")
        timeout = (new Date()).getTime() - GPSControle.time 
        if (timeout > 600000) or ((GPSControle.accuracy - position.coords.accuracy) > 2)
            GPSControle.gps = position.coords.latitude+", "+position.coords.longitude
            GPSControle.accuracy = position.coords.accuracy 
            GPSControle.time = (new Date()).getTime()
            console.log("latlong: "+GPSControle.gps + " accuracy:"+position.coords.accuracy)
            @mostraGPS()
            @save()


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
      @atividadesview.clearUI()
      @atividadesview.sincronizar()
      window.atividadesview = @atividadesview

      $.mobile.changePage("#pglogado",{changeHash:false})                    
    else
      $.mobile.changePage("#pglogin",{changeHash:false})


class window.Atividades
  @tolerancia = 5
  
  sincronizar: ()->
        atividadesPendentes = @getAtividades() 

        $.post( "http://sav.wancharle.com.br/salvar/", {'usuario':userview.getUsuario(),'json':JSON.stringify(atividadesPendentes)}, 
            ()-> 
                console.log('envio ok')
                $( "#painel" ).panel( "close" )
            ,'json')
        .done((data)->
              atividadesview.setAtividades(data)
              atividadesview.atualizaUI()

        ).fail((error,textstatus)->
            alert('Não foi possível enviar os dados registrados ao servidor. Isso ocorre provavelmente por falta de conexão de dados no momento. Tente novamente quando tver um conexão de internet estável')
            console.log(textstatus)
        )
         
  getAtividades: ()->
    ativs= window.localStorage.getObject('lista_de_atividades')
    if ativs
      return ativs
    else
      return new Array()

  setAtividades:(atividades)->
    window.localStorage.setObject('lista_de_atividades',atividades)

  fim: (id)->
    n_presentes = parseInt($('#txtpresentes'+id).val())
    n_participantes = parseInt($('#txtparticipantes'+id).val())
    if isInteger(n_presentes) and isInteger(n_participantes)
      if n_presentes < n_participantes
          alert("O número de pessoas presentes deve ser igual ou superior ou número de pessoas participantes da atividade!")
          return

      horario_fim = formatahora(new Date())
      d = new Date()
      d.setMinutes(d.getMinutes()-Atividades.tolerancia)
      limite_fim = formatahora(d)


      ativs = @getAtividades()
      for ativ, i in ativs
        if parseInt(ativ.id) == parseInt(id)
          if ativ.h_inicio_registrado
            if limite_fim > ativ.h_fim
              alert("Periodo para finalizar esta atividade terminou.
              Por isso, esta atividade NÃO será registrada.")
              return false

            ativ.h_fim_registrado = horario_fim
            ativ.gps = GPSControle.gps
            ativ.numero_de_presentes = n_presentes
            ativ.numero_de_participantes = n_participantes
            ativ.realizada=true
          else
            alert("É preciso iniciar a atividade antes de finalizar!")
            return false
      @setAtividades(ativs)
      atividadesview.atualizaUI()
    else
      alert("Para finalizar a atividade é preciso informar o número de participantes e presentes")
      return false


  start:(id)->
    ativs = @getAtividades()
    for ativ, i in ativs
      if parseInt(ativ.id) == parseInt(id)
        horario_inicio = formatahora(new Date())
        d = new Date()
        d.setMinutes(d.getMinutes()+Atividades.tolerancia)
        limite_inicio = formatahora(d)
        if limite_inicio > ativ.h_inicio
          ativ['h_inicio_registrado'] = horario_inicio
          $('li.ativ'+id+ ' button.ui-btn.start').hide()
          $('li.ativ'+id+ ' p.h_inicio_registrado').show()
          $('li.ativ'+id+ ' p.h_inicio_registrado').html('Iniciou as '+horario_inicio.slice(0,5)+'h')
        else
          alert("Vc não pode iniciar esta atividade ainda!")
        
    @setAtividades(ativs) 
  atualizaOntem: (ativ) ->
    li = "<li>"
    li+="<h2 data-inset='false'>"+ativ['h_inicio'].slice(0,5)+"h - "+ativ['h_fim'].slice(0,5)+"h</h2><div>"
    li+="<p> Gerência: "+ativ['gerencia']+ "</p>"
    li+="<span style='display:none' class='data'> "+ativ['data']+ '</span>'
    if ativ.realizada
      li+="<p>Realizada de "+ativ['h_inicio_registrado'].slice(0,5)+"h às "+ativ['h_fim_registrado'].slice(0,5)+"h</p>"
    else
      li+="<p>De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    if ativ['tipo'] == Atividade.TIPO_AULA
        li+="<p> Participantes/Presentes: "+ ativ['numero_de_participantes'] + "/" + ativ['numero_de_presentes'] + "</p>"
        
    li+="<p>GPS: " + ativ['gps']+ "</p>"
    li+="<p>Professor: "+ativ['usuario']+"</p>"
    return li+"</div></li>"

  atualizaHoje: (ativ) ->
    li = "<li class='ativ"+ativ.id+"' data-role='collapsible' data-iconpos='right' data-inset='false'>"
    li+="<h2 data-inset='false'>"+ativ['h_inicio'].slice(0,5)+'h - '+ativ['h_fim'].slice(0,5)+"h</h2>"
    li+="<span style='display:none' class='data'> "+ativ['data']+ '</span>'
    li+="<p> Gerência: "+ativ['gerencia']+ "</p>"
    li+="<p> Local: "+ativ['local']+"</p>"
    li+="<p> De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    li+="<div data-role=\"fieldcontain\">
      <label for=\"txtpresentes#{ativ.id}\">Presentes:</label>
      <input name=\"txtpresentes#{ativ.id}\" class=\"numero\" id=\"txtpresentes#{ativ.id}\" step=\"1\"  value=\"#{getIntVazio(ativ.numero_de_presentes)}\" type=\"number\"/>
      </div>
      <div data-role=\"fieldcontain\">
      <label for=\"txtparticipantes#{ativ.id}\">Participantes:</label>
      <input name=\"txtparticipantes#{ativ.id}\" class=\"numero\" id=\"txtparticipantes#{ativ.id}\" step=\"1\"  value=\"#{getIntVazio(ativ.numero_de_participantes)}\" type=\"number\"/>
      </div>"
      
    li+='<div class="ui-grid-b">
    <div class="ui-block-a">'
    if ativ.h_inicio_registrado
      li+='<p class="h_inicio_registrado">Iniciou as '+ativ.h_inicio_registrado.slice(0,5)+ 'h</p>'
    else
      li+='<button class="ui-btn start" onclick="atividadesview.start('+ativ.id+')">iniciar</button><p style="display:none" class="h_inicio_registrado"></p>'
    li+='</div>
    <div class="ui-block-b"> </div>
    <div class="ui-block-c"> <button class="ui-btn" onclick="atividadesview.fim('+ativ.id+')">finalizar</button></div>
</div>'
    li+="</li>"
    return li


  atualizaAmanha: (ativ) ->
    li = "<li >"
    li+="<h2 data-inset='false'>"+ativ['h_inicio'].slice(0,5)+"h - "+ativ['h_fim'].slice(0,5)+"h</h2><div>"
    li+="<p> Gerência: "+ativ['gerencia']+ "</p>"
    li+="<span  style='display:none' class='data'> "+ativ['data']+ '</span>'
    li+="<p>Local: "+ativ['local']+"</p>"
    li+="<p>De "+ativ['h_inicio'].slice(0,5)+"h às "+ativ['h_fim'].slice(0,5)+"h</p>"
    li+="<p>Professor: "+ativ['usuario']+ "</p>"
    return li+"</div></li>"

  atualizaUI: ()->
      atividades = @getAtividades()
      #d=new Date()
      #alert(d)
      #alert(formatadata(d))

      hoje = str2datePT(formatadata(new Date())) 
      #alert(hoje)
      if atividades
          htmlhoje = ""
          htmlontem = ""
          htmlamanha = ""
          for ativ in atividades
            if (str2datePT(ativ.data)< hoje) or (ativ.realizada==true)
              htmlontem += @atualizaOntem(ativ)
            else if str2datePT(ativ.data) == hoje
              htmlhoje += @atualizaHoje(ativ)
            else
              htmlamanha += @atualizaAmanha(ativ)

          $('#ulhoje').html(htmlhoje)
          $('#ulontem').html(htmlontem)
          $('#ulamanha').html(htmlamanha)
          $('#ulamanha,#ulontem').listview({ 
            autodividers:true,
            autodividersSelector:  ( li ) ->
                  return $(li).find('.data').text()
          }).listview('refresh')

          $('#ulhoje').listview().listview('refresh')
          
          #fix: ao atualizar um collapsible eh necessario chamar sua classe
          $('div[data-role=collapsible]').collapsible()
          $('li[data-role=collapsible]').collapsible()
          $('input.numero').textinput()
          $('input.numero').textinput('refresh')
          #fimfix.

  clearUI: ()->
          htmlhoje = ""
          htmlontem = ""
          htmlamanha = ""
          $('#ulhoje').html(htmlhoje)
          $('#ulontem').html(htmlontem)
          $('#ulamanha').html(htmlamanha)
          $('#ulamanha,#ulontem').listview().listview('refresh')

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

    mostraHistorico: ()->
      atividadesview.sincronizar()
               
    positionSucess: (gps) ->
        @userview.load()

    positionError: (error) ->
        alert('Não foi possível obter sua localização. Verifique as configurações do seu smartphone.') 

    main: () ->
        console.log('Received Event: onDeviceReady' )       
        window.userview=new UserView()
        userview.load()
        window.gpscontrole = new GPSControle()


window.ativtest = [
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"1", usuario:"fabricia", data:"16/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"2", usuario:"fabricia", data:"16/11/2014", h_inicio: "08:00", h_fim: "08:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"3", usuario:"fabricia", data:"16/11/2014", h_inicio: "09:00", h_fim: "09:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"4", usuario:"fabricia", data:"22/10/2014", h_inicio: "07:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"5", usuario:"fabricia", data:"22/10/2014", h_inicio: "08:00", h_fim: "08:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"6", usuario:"fabricia", data:"19/10/2014", h_inicio: "09:00", h_fim: "09:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"7", usuario:"fabricia", data:"21/10/2014", h_inicio: "20:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA },
  {gerencia:"RBC/ENE/JS", local:"EDMA", id:"8", usuario:"fabricia", data:"21/10/2014", h_inicio: "21:00", h_fim: "07:30", tipo: Atividade.TIPO_AULA },
  ]

#window.localStorage.setObject('lista_de_atividades',window.ativtest);
