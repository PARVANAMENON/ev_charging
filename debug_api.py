import http.cookiejar
import urllib.request
import json

login_url = 'http://localhost:5000/api/login'
vehicles_url = 'http://localhost:5000/api/vehicles'

jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

login_data = json.dumps({'username': 'admin', 'password': 'admin123'}).encode('utf-8')
req = urllib.request.Request(login_url, data=login_data, headers={'Content-Type': 'application/json'})
resp = opener.open(req)
print('login', resp.status, resp.read().decode())

req2 = urllib.request.Request(vehicles_url)
resp2 = opener.open(req2)
print('vehicles', resp2.status, resp2.read().decode())
