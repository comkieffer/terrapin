
import urllib.request, urllib.parse

class FormatError(Exception):
	pass

class PastebinError(Exception):
	pass

class Pastebin:

	_api_url = 'http://pastebin.com/api/api_post.php'

	privacy_values = {
		'listed': 0,
		'unlisted': 1,
		'private': 2
	}

	expiration_values = ('N', '10M', '1H', '1D', '1W', '2W', '1M')

	def __init__(self, api_key):
		self.api_key = api_key


	def paste(self, content,
		title = None, privacy = None, expiration = None, format = None):
		"""
		Create a new paste.

		Usage Example:


		"""

		# validate the parameters:
		if privacy and privacy not in self.privacy_values:
			raise FormatError(
				'Invalid <privacy> value. %s is not a valid privacy setting. See '
				'http://pastebin.com/api#7 for more information. Possible values '
				'are: listed, unlisted, private.', privacy
			)

		if expiration and expiration not in self.expiration_values:
			raise FormatError(
				'Invalid <expiration> value. %s is not a valid expiration '
				'setting. See http://pastebin.com/api#6 for more information. '
				'Possible values are %s', expiration, ', '.join(expiration)
			)


		args = {
			'api_dev_key': self.api_key,
			'api_paste_code': content,
			'api_option': 'paste'
		}

		if title:
			args['api_paste_name'] = title

		if privacy:
			args['api_paste_private'] = self.privacy_values[privacy]

		if expiration:
			args['api_paste_expire_data'] = expiration

		if format:
			args['api_paste_format'] = format

		args = urllib.parse.urlencode(args).encode('utf-8')
		with urllib.request.urlopen(self._api_url, args) as response:
			response_body = response.read().decode('utf-8')

			if response_body.startswith('Bad API request'):
				raise PastebinError(response_body)

		pastebin_code = response_body[-8:]
		return response_body, pastebin_code


class FlaskPastebin(Pastebin):

	def __init__(self, app = None):
		if app:
			self.init_app(app)


	def init_app(self, app):
		api_key  = app.config['PASTEBIN_API_KEY']

		super().__init__(api_key)
