
import xlwt
from django.http import HttpResponse
from datetime import datetime                                                                                                                                                        

 
def export_xls(modeladmin, request, queryset):
    meta = modeladmin.model._meta
    filename = u'%s.xls' % meta.verbose_name_plural.lower()
 
    def get_verbose_name(fieldname):
        name = list(filter(lambda x: x.name == fieldname, meta.fields))
        if name:
            return (name[0].verbose_name or name[0].name).upper()
        return fieldname.upper()
 
    response = HttpResponse(mimetype='application/ms-excel')
    response['Content-Disposition'] = "attachment;filename=%s" % filename
 
    wbk = xlwt.Workbook()
    sht = wbk.add_sheet(str(meta.verbose_name_plural))
    date_format = xlwt.XFStyle()
    date_format.num_format_str = 'dd/mm/yyyy'                                                                                                                                        

    time_format = xlwt.XFStyle()
    time_format.num_format_str = 'HH:MM'

    for j, fieldname in enumerate(modeladmin.list_display):
        sht.write(0, j, get_verbose_name(fieldname))
 
    date_style = xlwt.easyxf(num_format_str='DD/MM/YYYY')
    for i, row in enumerate(queryset):
        for j, fieldname in enumerate(modeladmin.list_display):
            try:
                atributo = getattr(modeladmin, fieldname)(row)
                sht.write(i + 1, j,atributo)
            except:
                if fieldname.upper() == 'DATA':
                    sht.write(i + 1, j,row.data,date_format)
                elif "hor" in fieldname:
                    sht.write(i + 1, j, getattr(row, fieldname, ''),time_format)
                else:
                    sht.write(i + 1, j, getattr(row, fieldname, ''))
 
    wbk.save(response)
    return response
 

# vim: set ts=4 sw=4 sts=4 expandtab: 

