#-*- coding: utf-8 -*-


from django import forms
from django.contrib import admin
from .models import Professor, Atividade, Planilha
from .exporta_excel import export_xls 
import xlrd 
class AtividadeAdmin(admin.ModelAdmin):
    date_hierarchy = 'data'
    search_fields = ('local','gerencia','numero_de_presentes', 'numero_de_participantes')
    list_filter =  ( 'professor','realizada')
    list_display = ( 'codigo_aula','local','gerencia','instrutor','data','horario_inicio', 'horario_fim', 'gps', 'numero_de_presentes', 'numero_de_participantes','realizada')
    #exclude= ("gps", "horario_fim_registrado","horario_inicio_registrado", "numero_de_presentes","numero_de_participantes")
    fields = ('professor',('tipo','codigo_aula'),'local', 'gerencia', 'data',('horario_inicio','horario_fim'),'realizada')
    def instrutor(self,ob):
        return str(ob.professor)
    instrutor.short_description="professor"

admin.site.add_action(export_xls, 'Exportar selecionados pro excel')

class PlanilhaAdmin(admin.ModelAdmin):
    date_hierarchy = 'data'
    search_fields = ('observacao',)
    list_display = ('planilha_xls','observacao','data')
   
    actions = ['importar_planilha_selecionada']
    def importar_planilha_selecionada(self,request,queryset):
        for q in queryset:
            q.importar()
    
admin.site.register(Professor)
admin.site.register(Atividade,AtividadeAdmin)
admin.site.register(Planilha,PlanilhaAdmin)


# vim: set ts=4 sw=4 sts=4 expandtab: 

