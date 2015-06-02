
from flask.ext.script import Manager, prompt_bool

from app              import db


db_manager = Manager(usage='Perform Database operations')


@db_manager.command
def create():
	print('Creating Database ... ')
	db.create_all()


@db_manager.option('-f', '--force', dest='force', required=False)
def drop(force=False):
	if force or prompt_bool('Are you sure you want to drop the database ?'):
		print('Dropping all database tables ...')
		db.drop_all()
	else:
		print('Aborting. No changes have been made.')


@db_manager.option('-f', '--force', dest='force', default=False)
def recreate(force=False):
	drop(force)
	create()


@db_manager.command
def populate():
	from .users import make_users
	print('Making new users ...')
	make_users()

	from .checkins import populate as make_checkins
	print('Making new checkins ....')
	make_checkins()
