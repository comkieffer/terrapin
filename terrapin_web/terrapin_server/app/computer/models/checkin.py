
from datetime           import datetime
from sqlalchemy.orm.exc import NoResultFound

from app                import db
from app.json           import JsonSerializableModel
from app.auth.models    import User

from .mixins            import PositionMixin
from .world             import World
from .computer          import Computer
from ..signals          import NewDeviceSeen, NewCheckinReceived

class MissingWorldError(Exception):
	pass

class APIAuthenticationError(Exception):
	pass

class ComputerCheckin(db.Model, JsonSerializableModel, PositionMixin):
	"""
	The ComputerConfig Model stores checkin data in the database. It is
	basically a log of all the checkins we have received so far.

	When a checkin is received it locates the corresponding World and Computer
	models so that it can udate those too. It also emits signals to inform other
	parts of the application that a new checkin has been received.

	It emits the following signals:
		- NewDeviceSeen
		- NewCheckinReceived
	"""

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
		backref = db.backref('checkins', lazy = 'dynamic'))

	message_type     = db.Column(db.String(100))
	task             = db.Column(db.String(1000))
	status           = db.Column(db.String(1000))

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

		self.fuel_level       = data.get("fuel", None)
		self.total_blocks_dug = data.get("total_blocks_dug", None)
		self.total_moves      = data.get("total_moves", None)

		self.created_at = datetime.now()

		self.updatePosition(data)
		self.updateWorld(data)
		self.updateComputer(data)

		# We can finally tell the world about this checkin.
		NewCheckinReceived.send('checkin view', checkin = self)


	def updateWorld(self, data):
		"""
		Locate the world that this checkin belongs to and update it with the
		data from the checkin.

		If the world doesn't exist we raise an error.
		"""

		world = World.query.filter_by(
			owner_id = self.owner_id, name = data['world_name']
		).first()

		if not world:
			raise MissingWorldError(
				'Unable to locate a world called "{}" for this user. Have you '
				'created it through the web UI ?'.format(data['world_name'])
			)

		world.update(data)
		self.parent_world_id = world.id


	def updateComputer(self, data):
		"""
		Locate the computer that generated this checkin and udate its internal
		data with the new checkin data.
		"""

		try:
			computer = Computer.query.filter_by(
				parent_world_id = self.parent_world_id,
				computer_id = data['computer_id']
			).one()
			computer.update(data)
		except NoResultFound:
			data['owner_id']        = self.owner_id
			data['parent_world_id'] = self.parent_world_id
			computer = Computer(data)

			db.session.add(computer)

			NewDeviceSeen.send('ComputerCheckin:__init__', device = computer)


	def __repr__(self):
		status = self.status[:40]
		if len(status) < len(self.status):
			status = status[:-3]
			status = status + '...'

		return '<Computer Checkin for {} (id: {}) - {}>'.format(
			self.computer_name, self.computer_id, status
		)

