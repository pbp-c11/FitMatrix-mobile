content = open('templates/base.html', 'r', encoding='utf-8').read()
# Only fix comparison operators without spaces - be careful not to touch pipe operators
content = content.replace('request.path==home_url', 'request.path == home_url')
content = content.replace("app_name=='search'", "app_name == 'search'")
content = content.replace("app_name=='scheduling'", "app_name == 'scheduling'")
content = content.replace("url_name=='list'", "url_name == 'list'")
# Fix != but be careful about context
content = content.replace("!='booking'", "!= 'booking'")
# Fix broken pipe (space before pipe)
content = content.replace("' ' |add:", "' '|add:")
open('templates/base.html', 'w', encoding='utf-8').write(content)
print('Done')
