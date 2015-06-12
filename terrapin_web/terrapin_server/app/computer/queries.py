
from collections import Counter

from sqlalchemy      import desc
from flask.ext.login import current_user

from .models import ComputerCheckin, Computer, World

def getWorldsFor(user):
	"""
	Return a serializable list containing all the worlds that this user can
	access.
	"""

	return World.query.filter_by(owner = user).all()

def getCheckinsFor(computer):
	return ComputerCheckin.query.filter_by(
		world_id = computer.parent_world_id,
		computer_id = computer_id,
		).order_by(desc(created_at)) \
		 .all()


def getTaskFrequenciesFor(computer):
	checkins = ComputerCheckin.query.filter_by(
		parent_world_id = computer.parent_world_id,
		computer_id     = computer.id,
		message_type    = 'task-start'
	).all()

	task_counter = Counter()
	for checkin in checkins:
		task_counter[checkin.task] += 1

	return task_counter.most_common()


def getFuelHistoryFor(computer):
	checkins = getCheckinsFor(computer)

	return [(ck.created_at, ck.fuel_level) for ck in checkins]


