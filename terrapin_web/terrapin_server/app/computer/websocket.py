import logging, json, os

from hashlib        import sha1
from itsdangerous   import URLSafeTimedSerializer

from flask.sessions import session_json_serializer
from werkzeug.utils import import_string
from sqlalchemy import create_engine

from tornado.websocket import WebSocketHandler

from app.json import CustomJSONEncoder
from app.appfactory import AppFactory
from app.auth.models import User

from .signals import NewCheckinReceived
from .models import *

# TODO: Find a way to filter the checkins on the client.
#
#	Do we implment a protocol ?
#	Add some query parameters to the url handler ?
#	Do something else ?
#
#	When a checkin arrives we just need to check the filter against the checkin.

class FlaskSessionParser:

	def __init__(self):
		self.flask_config = import_string('app.settings.DevelopmentConfig')

		self.serializer = URLSafeTimedSerializer(
		    self.flask_config.SECRET_KEY,
			salt          = 'cookie-session',
		    serializer    = session_json_serializer,
		    signer_kwargs = {
		    	'key_derivation': 'hmac',
		    	'digest_method' : sha1
		    }
		)

	def parse(self, session_cookie):
		return self.serializer.loads(session_cookie)

class CheckinHandler(WebSocketHandler):

	clients = {}
	session_parser = FlaskSessionParser()

	def open(self):
		self.logger = logging.getLogger(__name__)
		self.logger.info(
			'New listener registerred on checkin streamer> world = %s, '
			'computer = %s',
				self.get_query_argument('world_id', 'N/A'),
				self.get_query_argument('computer_id', 'N/A')
		)

		session = self.session_parser.parse(self.get_cookie('session'))

		# To access the database we need a request context.
		with AppFactory.app_instance.app_context():

			user = User.query.get(session['user_id'])

			# We can't continue if we don't have a valid user.
			if not user:
				self.error('Invalid session cookie')

			# If we were able to load a user we need to check that he can access the
			# stream he is asking for.
			world_id = self.get_query_argument('world_id', None)

			# Only admins can see the entire stream of checkins
			if not world_id:
				if user.is_admin:
					CheckinHandler.clients[self] = {
						'emitter': self,
						'filter': lambda ck: True
					}
				else:
					self.error('Malformed request. Missing world_id')
					return

			# At this point we can be sure that the world_id query param was set.
			# Now we just need to make sure that it points to a world the user
			# controls.

			world = World.query.get(world_id)

			if not world:
				self.error('Invalid world ID')
				return

			if not(user.is_admin) and not(world.owner_id == user.id):
				self.error('Unauthorized. You are not the owner of the world')
				return

			# Time to look at the computer id now.
			computer_id = self.get_argument('computer_id', None)

			if computer_id:
				computer = Computer.query.get(computer_id)

				if computer:
					CheckinHandler.clients[self] = {
						'emitter': self,
						'filter': lambda ck:
							(int(ck.computer_id)     == int(computer_id)) and
							(int(ck.parent_world_id) == int(world_id))
					}
					return
				else:
					self.error('Invalid computer_id.')
					return
			else:
				CheckinHandler.clients[self] = {
					'emitter': self,
					'filter': lambda ck: int(ck.parent_world_id) == int(world_id)
				}
				return




	def on_close(self):
		self.logger.info('Client disconnected from checkin streamer.')
		CheckinHandler.clients.pop(self, None)


	def send_checkin(self, checkin):
		self.write_message(json.dumps(
			{ 'data': checkin },
			cls=CustomJSONEncoder, indent = 4
		))


	def error(self, error_message):
		self.write_message(json.dumps(
			{ 'error': error_message }
		))


@NewCheckinReceived.connect
def send_updates_on_checkin(sender, checkin):
	for client, item in CheckinHandler.clients.items():
		if item['filter'](checkin):
			client.send_checkin(checkin)
