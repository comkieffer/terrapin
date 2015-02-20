from datetime import datetime

def register_filters(app):

	@app.template_filter('pluralize')
	def pluralize(number, singular = '', plural = 's'):
		return singular if number <= 1 else plural

	@app.template_filter('datetime')
	def datetimeformat(value, format='%d %B %Y %H:%M'):
		return value.strftime(format)

	@app.template_filter('time')
	def make_time(value):
		return value.strftime('%H:%M')

	@app.template_filter('date')
	def make_date(value, short = False):
		if not short :
			return value.strftime('%d %B %Y')
		else:
			return value.strftime('%d %b %Y')

	@app.template_filter('prettify_date')
	def prettify_date(date):
		s = diff.seconds

		if diff.days > 7 or diff.days < 0:
			return date.strftime('%d %b %y')
		elif diff.days == 1:
			return '1 day ago'
		elif diff.days > 1:
			return '{:.0f} days ago'.format(diff.days)
		elif s <= 1:
			return 'just now'
		elif s < 60:
			return '{:.0f} seconds ago'.format(s)
		elif s < 120:
			return '1 minute ago'
		elif s < 3600:
			return '{:.0f} minutes ago'.format(s/60)
		elif s < 7200:
			return '1 hour ago'
		else:
			return '{:.0f} hours ago'.format(s/3600)
