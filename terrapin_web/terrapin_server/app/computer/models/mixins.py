
from app import db

class PositionMixin:
	"""
	This is just a utility class to expose the rel_pos and abs_pos properties in
	both the Comuter class and the ComputerCheckin class without dduplicating
	too much code.
	"""

	abs_pos_x        = db.Column(db.Integer)
	abs_pos_y        = db.Column(db.Integer)
	abs_pos_z        = db.Column(db.Integer)

	rel_pos_x        = db.Column(db.Integer)
	rel_pos_y        = db.Column(db.Integer)
	rel_pos_z        = db.Column(db.Integer)

	def updatePosition(self, data):
		if data.get('rel_pos_x'):
			self.rel_pos_x = data["rel_pos_x"]
			self.rel_pos_y = data["rel_pos_y"]
			self.rel_pos_z = data["rel_pos_z"]

		if data.get('abs_pos_x'):
			self.abs_pos_x = data["abs_pos_x"]
			self.abs_pos_y = data["abs_pos_y"]
			self.abs_pos_z = data["abs_pos_z"]

	@property
	def rel_pos(self):
		return (self.rel_pos_x, self.rel_pos_y, self.rel_pos_z)

	@property
	def abs_pos(self):
		return (self.rel_pos_x, self.rel_pos_y, self.rel_pos_z)

