

from collections import namedtuple
from .models import ComputerCheckin

# Unused ... I shoudl do some error checking ...
class InvalidWorldName(Exception):
	pass

def getComputers(world_name = None):
	if world_name:
		return ComputerCheckin.query \
			.filter_by(world_name = world_name) \
			.distinct(ComputerCheckin.computer_id)    \
			.group_by(ComputerCheckin.computer_id)    \
			.all()
	else: 
		return ComputerCheckin.query \
			.distinct(ComputerCheckin.computer_id) \
			.group_by(ComputerCheckin.computer_id) \
			.all()


WorldInfo = namedtuple('WorldInfo', ['name', 'num_checkins', 'computers'])

def getWorldsInfo():
	worlds = ComputerCheckin.query \
		.distinct(ComputerCheckin.world_name) \
		.group_by(ComputerCheckin.world_name) \
		.all()

	retval = {}
	for world in worlds:
		checkin_count = ComputerCheckin.query         \
			.filter_by(world_name = world.world_name) \
			.count()

		retval[world.world_name] = WorldInfo(
			world.world_name, 
			checkin_count,
			getComputers(world.world_name)
		)	

	return retval