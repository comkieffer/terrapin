import logging, json

from tornado.websocket import WebSocketHandler

from app.json import CustomJSONEncoder
from .signals import NewCheckinReceived

# TODO: Find a way to filter the checkins on the client.
#
#	Do we implment a protocol ?
#	Add some query parameters to the url handler ?
#	Do something else ?
#
#	When a checkin arrives we just need to check the filter against the checkin.

class CheckinHandler(WebSocketHandler):

	clients = set()

	def open(self):
		self.logger = logging.getLogger(__name__)
		self.logger.info('New client registered on checkin streamer')

		CheckinHandler.clients.add(self)


	def on_close(self):
		self.logger.info('Client disconnected from checkin streamer.')

		CheckinHandler.clients.remove(self)


	def send_checkin(self, checkin):
		self.write_message(json.dumps(checkin, cls=CustomJSONEncoder, indent = 4))


@NewCheckinReceived.connect
def send_updates_on_checkin(sender, checkin):
	for client in CheckinHandler.clients:
		client.send_checkin(checkin)
