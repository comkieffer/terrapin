from datetime import datetime

def pluralize(number, singular = '', plural = 's'):
	return singular if number <= 1 else plural

def datetimeformat(value, format='%d %B %Y %H:%M'):
	return value.strftime(format)

def make_time(value):
	return value.strftime('%H:%M')

def make_date(value, short = False):
	if not short :
		return value.strftime('%d %B %Y')
	else:
		return value.strftime('%d %b %Y')

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

def constrain(val, min_, max_):
	val = min_ if val < min_ else val
	val = max_ if val > max_ else val

	return val

def tick2mctime(ticks):
	if ticks == 0:
		return '0 days'

	days, remainder    = divmod(ticks, 24000)
	hours, remainder   = divmod(remainder, 1000)
	minutes, remainder = divmod(remainder, 100)

	days_str = "{} days, ".format(days) if days > 1 else "1 day, "
	hours_str = "{} hours, ".format(hours) if hours > 1 else "1 hour, "
	minutes_str = "{} minutes, ".format(minutes) if minutes > 1 else "1 minute, "

	time_str =  days_str if days > 0 else ""
	time_str += hours_str if hours > 0  else ""
	time_str += minutes_str if minutes > 0 else ""

	# Trim the trailing ', ' that appears if minutes_str is empty
	if time_str[-2:] == ', ':
		time_str = time_str[:-2]

	return time_str

