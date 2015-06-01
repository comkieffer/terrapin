
import random

from faker                   import Faker
from werkzeug.datastructures import MultiDict
from flask.ext.script        import Manager, prompt_bool

from app                     import db
from app.auth.models         import User
from app.computer.models     import ComputerCheckin, World

from .dictionary import TASKS, STATUSES, WORLDS

checkin_manager = Manager(usage='Create checkins.')


@checkin_manager.command
def populate():
	"""
	Populate the checkins table such that every user has several computers active
	on different worlds.
	"""

	fake = Faker()
	fake.seed(5789)

	# Let's create some worlds for each user.
	users = User.query.all()

	# We'll create some worlds for each user
	checkins_created = 0
	for user in users:

		if user.user_name == 'Admin':
			continue

		num_worlds = fake.random_int(min=1, max=10)
		print('\nCreating computer checkins for user {}\n'.format(user.user_name))

		for k in range(1, num_worlds):
			world_name = random.choice(WORLDS) + ' ' + str(k)

			world_computers = [
				(0, 'Test Computer 0'), (1, 'Test Computer 1'),
				(2, 'Test Computer 2'), (3, 'Test Computer 3'),
				(4, 'Test Computer 4'), (5, 'Test Computer 5'),
				(6, 'Test Computer 6'), (7, 'Test Computer 7'),
				(8, 'Test Computer 8'), (9, 'Test Computer 9')
			]

			# Before we can checkin we need to create a world:
			new_world = World(world_name, user)
			db.session.add(new_world)

			# We can now make our computers checkin
			world_age = 0
			for j in range(1, fake.random_int(min=1, max=50)):
				computer   = random.choice(world_computers)
				world_age += fake.random_int(min=0, max=24000)

				checkin(
					user.api_token, world_name, computer[0], computer[1],
					random.choice(TASKS), random.choice(STATUSES), world_age
				)
				checkins_created += 1

	print('Create {} checkins.\n'.format(checkins_created))

@checkin_manager.option('-a', '--api-token', dest='api_token', required=True)
@checkin_manager.option('-w', '--world', dest='world', required=True)
@checkin_manager.option('-c', '--computer', dest='computer_id', default=1)
@checkin_manager.option('-n', '--name', dest='computer_name', required=True)
@checkin_manager.option('-t', '--task', dest='task', required=True)
@checkin_manager.option('-s', '--status', dest='status', required=True)
def checkin(api_token, world, computer_id, computer_name, task, status, ticks):
	""" Create a checkin message with the specified parameters """

	data = MultiDict([
		('api_token', api_token),
		('world_name', world),
		('computer_id', computer_id),
		('computer_name', computer_name),
		('task', task),
		('status', status),

		('computer_type', 'Advanced Computer'),
		('world_ticks', 0),
		('type', 'checkin'),
	])

	checkin = ComputerCheckin(data)

	print(
		'Adding new checkin message for computer {} in world: {}: \n\t{}'
		.format(computer_name, world, checkin)
	)

	db.session.add(checkin)
	db.session.commit()
