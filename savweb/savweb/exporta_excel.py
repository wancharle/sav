
import xlwt
from django.http import HttpResponse
 
 
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
 
    for j, fieldname in enumerate(modeladmin.list_display):
        sht.write(0, j, get_verbose_name(fieldname))
 
    for i, row in enumerate(queryset):
        for j, fieldname in enumerate(modeladmin.list_display):
            sht.write(i + 1, j, getattr(row, fieldname, ''))
 
    wbk.save(response)
    return response


# vim: set ts=4 sw=4 sts=4 expandtab: 

