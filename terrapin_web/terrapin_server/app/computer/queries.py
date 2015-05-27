
from flask.ext.login import current_user

from .models import Computer, World

def getWorldsFor(user):
	"""
	Return a serializable list containing all the worlds that this user can
	access.
	"""

	worlds = Computer.query                 \
		.filter_by(owner_id = user.id)      \
		.group_by(Computer.world_name)      \
		.distinct(Computer.world_name)      \
		.all()

	worlds = [World(checkin.world_name, user) for checkin in worlds]

	return worlds

def aggregatedComputerData(computer_id, owner = None):
	owner = owner if owner else current_user

	checkins = ComputerCheckin.query                               \
		.filter_by(owner_id = owner.id, computer_id = computer_id) \
		.all()

	if length(checkins) > 1000:
		loggin.getLogger(__name__).warning(
			'Executed resource intensive API query: aggregatedData. Now would '
			'be a good time to start thinking about optimisation.'
		)

	ticks        = [c.world_ticks for c in checkins]
	fuel         = [c.fuel_level for c in checkins]
	blocks_moved = [c.total_moves for c in checkins]
	blocks_dug   = [c.total_blocks_dug for c in checkins]

	tasks = Counter()
	for checkin in checkins:
		tasks[checkin.task] += 1

	return {
		'ticks'        : ticks,
		'fuel'         : fuel,
		'block dug'    : blocks_dug,
		'blocks moved' : blocks_moved,
		'tasks'        : tasks.most_common()
	}
