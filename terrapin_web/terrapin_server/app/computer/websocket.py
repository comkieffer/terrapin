import logging, json

from tornado.websocket import WebSocketHandler

from app.json import CustomJSONEncoder
from .signals import new_checkin_received

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


@new_checkin_received.connect
def send_updates_on_checkin(sender, checkin):
	for client in CheckinHandler.clients:
		client.send_checkin(checkin)