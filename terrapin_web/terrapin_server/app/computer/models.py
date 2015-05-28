

from sqlalchemy.orm.exc import NoResultFound

from datetime import datetime

from app             import db
from app.json        import JsonSerializableModel
from app.auth.models import User

from .signals        import NewWorldSeen, NewDeviceSeen

import logging
logger = logging.getLogger(__name__)

class APIAuthenticationError(Exception):
	pass

class PositionMixin:
	"""
	This is just a utility class to expose the rel_pos and abs_pos properties in
	both the Comuter class and the ComputerCheckin class without dduplicating
	too much code.
	"""
	@property
	def rel_pos(self):
		return (self.rel_pos_x, self.rel_pos_y, self.rel_pos_z)

	@property
	def abs_pos(self):
		return (self.rel_pos_x, self.rel_pos_y, self.rel_pos_z)


class Computer(db.Model, JsonSerializableModel, PositionMixin):
	"""
	The Computer Class is a shaortcut that allows us to easily access the
	current state of any computer.

	When we create a checkin the relevant computer instance is created or
	updated so that we can trivially fetch the state of the computer. The data
	here replicates the data already contained in the checkins themselves but
	this interface is easier to grok.
	"""
	id               = db.Column(db.Integer, primary_key = True)

	owner_id         = db.Column(db.Integer, db.ForeignKey('user.id'))
	owner            = db.relationship('User')

	parent_world_id  = db.Column(db.Integer, db.ForeignKey('world.id'))
	parent_world     = db.relationship('World')

	computer_id      = db.Column(db.Integer)
	computer_name    = db.Column(db.String(100))
	computer_type    = db.Column(db.String(100))

	first_seen_at    = db.Column(db.Integer)
	age              = db.Column(db.Integer)

	current_task     = db.Column(db.String(1000))
	last_status      = db.Column(db.String(1000))

	abs_pos_x        = db.Column(db.Integer)
	abs_pos_y        = db.Column(db.Integer)
	abs_pos_z        = db.Column(db.Integer)

	rel_pos_x        = db.Column(db.Integer)
	rel_pos_y        = db.Column(db.Integer)
	rel_pos_z        = db.Column(db.Integer)

	fuel_level       = db.Column(db.Integer)
	total_blocks_dug = db.Column(db.Integer)
	total_moves      = db.Column(db.Integer)

	last_update      = db.Column(db.DateTime)
	num_checkins     = db.Column(db.Integer)

	def __init__(self, data):
		self.owner_id      = data['owner_id']

		self.parent_world_id = data['parent_world_id']

		self.computer_id   = data.get('computer_id')
		self.computer_name = data.get('computer_name')
		self.computer_type = data.get('computer_type')
		self.num_checkins  = -1

		self.first_seen_at = data.get('world_ticks')

		self.update(data)

	def update(self, data):
		self.current_task = data.get("task")
		self.last_status  = data.get("status")

		if data.get('rel_pos_x'):
			self.rel_pos_x = data["rel_pos_x"]
			self.rel_pos_y = data["rel_pos_y"]
			self.rel_pos_z = data["rel_pos_z"]

		if data.get('abs_pos_x'):
			self.abs_pos_x = data["abs_pos_x"]
			self.abs_pos_y = data["abs_pos_y"]
			self.abs_pos_z = data["abs_pos_z"]

		self.fuel_level       = data.get("fuel", None)
		self.total_blocks_dug = data.get("total_blocks_dug", None)
		self.total_moves      = data.get("total_moves", None)

		self.last_update  = datetime.now()
		self.num_checkins = self.num_checkins + 1
		self.age          = data['world_ticks'] - self.first_seen_at


	def recent_checkins(self, count = 5):
		checkins = ComputerCheckin.query                 \
			.filter_by(world_id = self.world_id)         \
			.order_by(ComputerCheckin.created_at.desc()) \
			.limit(count)                                \
			.all()

		return checkins

	@property
	def total_checkins(self):
		return ComputerCheckin.query \
			.filter_by(
				world_name = self.world_name,
				computer_id = self.computer_id
			).count()


class ComputerCheckin(db.Model, JsonSerializableModel, PositionMixin):

	id               = db.Column(db.Integer, primary_key = True)

	owner_id         = db.Column(db.Integer, db.ForeignKey('user.id'))
	owner            = db.relationship('User')

	parent_world_id  = db.Column(db.Integer, db.ForeignKey('world.id'))
	parent_world     = db.relationship('World')

	world_ticks      = db.Column(db.Integer)

	computer_id      = db.Column(db.Integer, db.ForeignKey('computer.id'))
	computer_name    = db.Column(db.String(100))
	computer_type    = db.Column(db.String(100))

	parent_computer  = db.relationship('Computer',
	backref          = db.backref('checkins', lazy = 'dynamic'))

	message_type     = db.Column(db.String(100))
	task             = db.Column(db.String(1000))
	status           = db.Column(db.String(1000))

	abs_pos_x        = db.Column(db.Integer)
	abs_pos_y        = db.Column(db.Integer)
	abs_pos_z        = db.Column(db.Integer)

	rel_pos_x        = db.Column(db.Integer)
	rel_pos_y        = db.Column(db.Integer)
	rel_pos_z        = db.Column(db.Integer)

	fuel_level       = db.Column(db.Integer)
	total_blocks_dug = db.Column(db.Integer)
	total_moves      = db.Column(db.Integer)

	created_at       = db.Column(db.DateTime())

	def __init__(self, data):
		owner = User.query                                \
			.filter_by(api_token = data.get("api_token")) \
			.first()

		if not owner:
			raise APIAuthenticationError(
				'Attempted to create a checkin with an invalid API token: {}' \
				.format(data.get("api_token"))
			)

		self.owner_id = owner.id

		self.world_ticks   = data.get("world_ticks")

		self.computer_id   = data.get("computer_id")
		self.computer_name = data.get("computer_name")
		self.computer_type = data.get("computer_type")

		self.message_type  = data.get("type")
		self.task          = data.get("task")
		self.status        = data.get("status")

		if data.get('rel_pos_x'):
			self.rel_pos_x = data["rel_pos_x"]
			self.rel_pos_y = data["rel_pos_y"]
			self.rel_pos_z = data["rel_pos_z"]

		if data.get('abs_pos_x'):
			self.abs_pos_x = data["abs_pos_x"]
			self.abs_pos_y = data["abs_pos_y"]
			self.abs_pos_z = data["abs_pos_z"]

		self.fuel_level       = data.get("fuel", None)
		self.total_blocks_dug = data.get("total_blocks_dug", None)
		self.total_moves      = data.get("total_moves", None)

		self.created_at = datetime.now()

		# Update the relevant computer model:
		# Note: We don't commit the changes since the caller will do it when he
		# commits the changes to ComputerCheckin
				# Update the relevant World model
		try:
			world = World.query.filter_by(
				owner_id = owner.id, name = data['world_name']
			).one()
			world.update(data)
		except NoResultFound:
			# This is the first commit to this world. We need to create it
			data['owner_id'] = owner.id
			world = World(data)

			db.session.add(world)

			# TODO: Figure out why this was breaking shit
			# NewWorldSeen.send('ComputerCheckin:__init__', world)

		self.parent_world_id = world.id


		try:
			computer = Computer.query.filter_by(
				parent_world_id = world.id
			).one()
			computer.update(data)
		except NoResultFound:
			data['owner_id']        = self.owner_id
			data['parent_world_id'] = self.parent_world_id
			computer = Computer(data)

			db.session.add(computer)

			# TODO: Figure out why this was breaking shit
			# NewDeviceSeen.send('ComputerCheckin:__init__', computer)

	def __repr__(self):
		status = self.status[:40]
		if len(status) < len(self.status):
			status = status[:-3]
			status = status + '...'

		return '<Computer Checkin for {} (id: {}) - {}>'.format(
			self.computer_name, self.computer_id, status
		)



class World(db.Model, JsonSerializableModel):
	"""
	A wrapper around world properties.

	Since there is no in-database representation of the world we use this
	convenience class that provides a reasonable abstraction.
	"""

	id             = db.Column(db.Integer, primary_key = True)

	name           = db.Column(db.String(100))
	age            = db.Column(db.Integer)
	total_checkins = db.Column(db.Integer)

	owner_id       = db.Column(db.Integer, db.ForeignKey('user.id'))
	owner          = db.relationship('User')

	def __init__(self, checkin):

		self.name           = checkin['world_name']
		self.owner_id       = checkin['owner_id']
		self.total_checkins = -1

		self.update(checkin)


	def update(self, checkin):
		self.total_checkins += 1

		# Note: This assumes that the world_ticks value is monotonically
		# increasing.
		self.age = checkin['world_ticks']


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
		return '<World "{}"" by {}>'.format(self.name, self.owner.user_name)

	def __json__(self):
		return {
			'name': self.name,
			'computers': self.computers
		}


