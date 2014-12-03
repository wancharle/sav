#!/usr/bin/env python
#-*- coding: utf-8 -*-

from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
import xlrd,datetime

from django.contrib import messages

class Professor(models.Model):
    user = models.ForeignKey(User)
    telefone = models.CharField(max_length=14)

    def __str__(self):
        return "{0}".format(self.user.username)
 
class Planilha(models.Model):
    observacao = models.CharField(max_length=200,null=True,blank=True)
    data = models.DateField(auto_now_add=True)
    planilha_xls = models.FileField(upload_to="dados/")

    def __str__(self):
        return "{0}".format(self.observacao)

    def importar(self,request):
        workbook = xlrd.open_workbook(self.planilha_xls.path)
        worksheet = workbook.sheet_by_index(0)
        num_rows = worksheet.nrows - 1
        curr_row = 0
        erros = ""
        while curr_row < num_rows:
            curr_row += 1
            row = worksheet.row(curr_row)
            try:
                
                codigo_aula = int(row[0].value)
                d = { }
                d['local'] = str(row[1].value)
                d['gerencia'] = str(row[2].value)
                userlogin = str(row[3].value).strip()
                d['professor'] = Professor.objects.get(user__username=userlogin) 
                d['data'] = datetime.datetime(*xlrd.xldate_as_tuple(row[4].value, workbook.datemode)) 
                t = str(row[6].value).strip()
                d['horario_inicio'] = datetime.datetime.strptime(t, '%H:%M')
                t = str(row[7].value).strip()
                d['horario_fim'] = datetime.datetime.strptime(t, '%H:%M')
                    
                ativ, created = Atividade.objects.update_or_create(codigo_aula=codigo_aula,data=d['data'], defaults=d)
            except Exception as e :
                 messages.add_message(request, messages.ERROR,"Erro na planilha linha {0}: {1}".format(curr_row+1,str(e)))

class Atividade(models.Model):
    #TIPO_EXPEDIENTE = 'EX'
    TIPO_ALMOCO = 'AL'
    TIPO_AULA = 'AU'
    TIPOS = ((TIPO_ALMOCO, u"Almoço"), (TIPO_AULA, u"Aula"))

    tipo  = models.CharField(max_length=2, default=TIPO_AULA,choices= TIPOS)
    codigo_aula = models.IntegerField(verbose_name=u"Código Aula")
    local = models.CharField(max_length=150)
    professor = models.ForeignKey(Professor)
    gerencia = models.CharField(max_length=100, verbose_name=u"gerência")
    numero_de_presentes = models.IntegerField(default=0,null=True,blank=True,verbose_name="presentes")
    numero_de_participantes = models.IntegerField(default=0,null=True, blank=True,verbose_name="participantes")
    realizada = models.BooleanField(default=False)
    data = models.DateField()
    horario_inicio = models.TimeField(verbose_name=u"horário início")
    horario_inicio_registrado = models.TimeField(null=True,blank=True)
    horario_fim = models.TimeField(verbose_name=u"horário fim")
    horario_fim_registrado = models.TimeField(null=True,blank=True)

    gps = models.CharField(null=True, blank=True,max_length=30,help_text=u"Coordenadas do gps no formato <latitude, longitude>. Exemplo: -43.004579, 25.445676" )

    class Meta:
        unique_together = ('codigo_aula','data')

    def __str__(self):
        return "{0}".format(self.codigo_aula)

    def clean(self):
       if self.tipo == Atividade.TIPO_AULA and (self.codigo_aula == None  or self.codigo_aula == 0) :
            raise ValidationError(u"Informe o código da aula para atividades do 'tipo aula'.")

        
# vim: set ts=4 sw=4 sts=4 expandtab: 

