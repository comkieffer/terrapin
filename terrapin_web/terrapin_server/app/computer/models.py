from app import db
from app.json import JsonSerializableModel
from datetime import datetime


class ComputerCheckin(db.Model, JsonSerializableModel):

	id = db.Column(db.Integer, primary_key = True)

	world_ticks   = db.Column(db.Integer)

	computer_id   = db.Column(db.Integer)
	computer_name = db.Column(db.String(100))
	computer_type = db.Column(db.String(100))

	message_type  = db.Column(db.String(100))
	task          = db.Column(db.String(1000))
	status        = db.Column(db.String(1000))

	pos_x = db.Column(db.Integer)
	pos_y = db.Column(db.Integer)
	pos_z = db.Column(db.Integer)

	fuel_level       = db.Column(db.Integer)
	total_blocks_dug = db.Column(db.Integer)
	total_moves      = db.Column(db.Integer)

	created_at = db.Column(db.DateTime())


	def __init__(self, data):
		self.world_ticks   = data["world_ticks"]

		self.computer_id   = data["computer_id"]
		self.computer_name = data["computer_name"]
		self.computer_type = data["computer_type"]

		self.message_type  = data["type"]
		self.task          = data["task"]
		self.status        = data["status"]

		if data.get('rel_pos_x'):
			self.pos_x = data["rel_pos_x"]
			self.pos_y = data["rel_pos_y"]
			self.pos_z = data["rel_pos_z"]

		self.fuel_level       = data.get("fuel", None)
		self.total_blocks_dug = data.get("total_blocks_dug", None)
		self.total_moves      = data.get("total_moves", None)

		self.created_at = datetime.now()

	def __repr__(self):
		return '<Computer Checkin for {} (id: {})>'.format(
			self.computer_name, self.computer_id
		)

