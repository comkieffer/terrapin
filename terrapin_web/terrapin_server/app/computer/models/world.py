

from app      import db
from app.json import JsonSerializableModel

from .computer import Computer

class World(db.Model, JsonSerializableModel):
	"""
	A wrapper around world properties.
	"""

	id             = db.Column(db.Integer, primary_key = True)

	name           = db.Column(db.String(100))
	description    = db.Column(db.String(10000))
	age            = db.Column(db.Integer)
	total_checkins = db.Column(db.Integer)

	owner_id       = db.Column(db.Integer, db.ForeignKey('user.id'))
	owner          = db.relationship('User')

	config_id      = db.Column(db.Integer, db.ForeignKey('checkin_config.id'))
	config         = db.relationship('CheckinConfig')


	def __init__(self, name, owner):

		self.name           = name
		self.owner_id       = owner.id
		self.total_checkins = -1
		self.age            = 0


	def update(self, checkin):
		self.total_checkins += 1
		self.age = max(int(checkin['world_ticks']), self.age)

	def computer(self, computer_id):
		return Computer.query.filter_by(
			parent_world_id = self.id,
			computer_id = computer_id
		).first()

	@property
	def devices(self):
		return Computer.query                     \
			.filter_by(parent_world_id = self.id) \
			.all()


	@property
	def computers(self):
		return Computer.query \
			.filter_by(
				parent_world_id = self.id, computer_type = 'Computer'
			).all()

	@property
	def advanced_comuters(self):
		return Computer.query \
			.filter_by(
				parent_world_id = self.id, computer_type = 'Advanced Computer'
			).all()

	@property
	def turtles(self):
		return Computer.query \
			.filter_by(
				parent_world_id = self.id, computer_type = 'Turtle'
			).all()

	@property
	def advanced_turtles(self):
		return Computer.query \
			.filter_by(
				parent_world_id = self.id, computer_type = 'Advanced Turtle'
			).all()


	@property
	def total_blocks_dug(self):
		turtle_digs    = sum([t.total_blocks_dug for t in self.turtles])
		adv_tutle_digs = sum([t.total_blocks_dug for t in self.advanced_turtles])
		return turtle_digs + adv_tutle_digs


	@property
	def total_moves(self):
		turtle_moves    = sum([t.total_moves for t in self.turtles])
		adv_turtle_moves = sum([t.total_moves for t in self.advanced_turtles])
		return turtle_moves + adv_turtle_moves


	def __repr__(self):
		return '<World {}: {}>'.format(self.id, self.name)
