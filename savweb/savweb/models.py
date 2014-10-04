#!/usr/bin/env python
#-*- coding: utf-8 -*-

from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError

class Professor(models.Model):
    user = models.ForeignKey(User)
    telefone = models.CharField(max_length=14)

    def __str__(self):
        return "{0}".format(self.user.username)
    
class Atividade(models.Model):
    #TIPO_EXPEDIENTE = 'EX'
    TIPO_ALMOCO = 'AL'
    TIPO_AULA = 'AU'
    TIPOS = ((TIPO_ALMOCO, u"Almoço"), (TIPO_AULA, u"Aula"))

    tipo  = models.CharField(max_length=2, default=TIPO_AULA,choices= TIPOS)
    codigo_aula = models.IntegerField(null=True,default=0,blank=True, verbose_name=u"Código Aula")
    local = models.CharField(max_length=150)
    professor = models.ForeignKey(Professor)
    gerencia = models.CharField(max_length=100, verbose_name=u"gerência")
    numero_de_presentes = models.IntegerField(default=0,null=True,blank=True)
    numero_de_participantes = models.IntegerField(default=0,null=True, blank=True)

    data = models.DateField()
    horario_inicio = models.TimeField(verbose_name=u"horário início")
    horario_inicio_registrado = models.TimeField(null=True,blank=True)
    horario_fim = models.TimeField(verbose_name=u"horário fim")
    horario_fim_registrado = models.TimeField(null=True,blank=True)

    gps = models.CharField(null=True, blank=True,max_length=30,help_text=u"Coordenadas do gps no formato <latitude, longitude>. Exemplo: -43.004579, 25.445676" )

    def __str__(self):
        return "{0}".format(self.codigo_aula)

    def clean(self):
       if self.tipo == Atividade.TIPO_AULA and (self.codigo_aula == None  or self.codigo_aula == 0) :
            raise ValidationError(u"Informe o código da aula para atividades do 'tipo aula'.")

        
# vim: set ts=4 sw=4 sts=4 expandtab: 

