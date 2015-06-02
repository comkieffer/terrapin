
import urllib.request, urllib.parse

from manage.checkins import checkin

API_URL = 'http://localhost:8100/api/checkin/'

# Using user julio14
#
# Worlds for juliio14:
#
# 	'This time I really wdon\'t die as often 2',
#	'The World where I don\'t die as often 1',

postdata = {
	'api_token'     : 'f867143e-12eb-4ab1-849f-faf0e7a9fef5',
	'world_name'    : 'The World where I don\'t die as often 1',
	'computer_id'   : 4,
	'computer_name' : 'Test Computer 4',
	'task'          : 'Testing Checkins',
	'status'        : 'This is coming along quite nicely',
	'computer_type' : 'Advanced Computer',
	'world_ticks'   : 1000,
	'type'          : 'checkin',
}

postdata = urllib.parse.urlencode(postdata).encode('utf-8')
with urllib.request.urlopen(API_URL, postdata) as response:
	print(response.read().decode('utf-8'))
