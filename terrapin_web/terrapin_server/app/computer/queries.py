
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

def getComputer(world_id, computer_id):
	return Computer.query.filter_by(
		parent_world_id	= world_id, cc_id = computer_id
	).first()


def getTaskFrequenciesFor(computer):
	task_counter = Counter()
	for checkin in computer.checkins.all():
		task_counter[checkin.task] += 1

	return task_counter.most_common()


def getFuelHistoryFor(computer):
	checkins = computer.checkins.all()

	return [(ck.created_at, ck.fuel_level) for ck in checkins]


