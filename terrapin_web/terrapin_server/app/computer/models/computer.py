
from datetime import datetime

from app      import db
from app.json import JsonSerializableModel

from .mixins  import PositionMixin

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

	cc_id            = db.Column(db.Integer)
	cc_name          = db.Column(db.String(100))
	type             = db.Column(db.String(100))

	first_seen_at    = db.Column(db.Integer)
	age              = db.Column(db.Integer)

	current_task     = db.Column(db.String(1000))
	last_status      = db.Column(db.String(1000))

	fuel_level       = db.Column(db.Integer)
	total_blocks_dug = db.Column(db.Integer)
	total_moves      = db.Column(db.Integer)

	last_update      = db.Column(db.DateTime)
	num_checkins     = db.Column(db.Integer)

	def __init__(self, data):
		self.owner_id = data['owner_id']

		self.parent_world_id = data['parent_world_id']

		self.cc_id   = data.get('computer_id')
		self.cc_name = data.get('computer_name')
		self.type    = data.get('computer_type')
		self.num_checkins  = -1

		self.first_seen_at = int(data.get('world_ticks'))

		self.update(data)


	def update(self, data):
		self.current_task = data.get("task")
		self.last_status  = data.get("status")

		self.fuel_level       = data.get("fuel", None)
		self.total_blocks_dug = data.get("total_blocks_dug", None)
		self.total_moves      = data.get("total_moves", None)

		self.last_update  = datetime.now()
		self.num_checkins = self.num_checkins + 1
		self.age          = int(data['world_ticks']) - self.first_seen_at

		self.updatePosition(data)


	def recent_checkins(self, count = 5):
		from .checkin import ComputerCheckin
		checkins = ComputerCheckin.query                 \
			.filter_by(world_id = self.world_id)         \
			.order_by(ComputerCheckin.created_at.desc()) \
			.limit(count)                                \
			.all()

		return checkins

	@property
	def total_checkins(self):
		from .checkin import ComputerCheckin
		return ComputerCheckin.query \
			.filter_by(
				world_name = self.world_name,
				computer_id = self.computer_id
			).count()



