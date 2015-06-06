
import random, string

from app      import db
from app.json import JsonSerializableModel

class CheckinConfig(db.Model, JsonSerializableModel):
	id = db.Column(db.Integer, primary_key = True)

	id_string = db.Column(db.String(10))
	config    = db.Column(db.String(1000))

	def __init__(self, config):
		self.id_string = self.makeIDString()
		self.config = config

	def makeIDString(self):
		return ''.join(random.choice(
			string.ascii_uppercase + string.ascii_lowercase + string.digits
		) for _ in range(8))

	def __repr__(self):
		return '<CheckinConfig %i: code = %s>' % (self.id, self.id_string)
