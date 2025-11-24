from django import template

register = template.Library()

@register.filter
def startswith(value, arg):
    """Cek apakah string diawali dengan arg tertentu"""
    if not value:
        return False
    if not isinstance(value, str):
        value = str(value)
    return value.startswith(arg)
