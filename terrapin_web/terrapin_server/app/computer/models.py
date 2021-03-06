from app import db
from datetime import datetime

class ComputerCheckin(db.Model):

	id = db.Column(db.Integer, primary_key = True)

	computer_id = db.Column(db.Integer)
	computer_name = db.Column(db.String(100))
	task = db.Column(db.String(1000))
	status = db.Column(db.String(1000))


	pos_x = db.Column(db.Integer)
	pos_y = db.Column(db.Integer)
	pos_z = db.Column(db.Integer)

	fuel = db.Column(db.Integer)

	created_at = db.Column(db.DateTime())


	def __init__(self, data):

		self.turtle_id = data["turtle_id"]
		self.turtle_name = data["turtle_name"]
		self.task = data["task"]
		self.status = data["status"]

		if data.get('rel_pos_x'):
			self.pos_x = data["rel_pos_x"]
			self.pos_y = data["rel_pos_y"]
			self.pos_z = data["rel_pos_z"]

		if data.get('fuel'):
			self.fuelLevel = data["fuel"]

		self.created_at = datetime.now()

	def __repr__(self):
		return '<Computer Checkin for {} (id: {})>'.format(
			self.turtle_name, self.turtle_id
		)

	def __json__(self):
		""" Quick and dirty JSON conversion """

		return {
			  'id': self.computer_id
			, 'name': self.computer_name
			, 'task': self.task
			, 'status': self.status
			, 'fuel': self.fuel
			, 'created_at': self.created_at
			, 'pos': [self.pos_x, self.pos_y, self.pos_z]
		}
