from flask.ext.script import Manager, Server

from app import db
from app.create_app import create_app
from app.turtle.models import TurtleCheckin

manager = Manager(
	create_app(
		'/vagrant/terrapin_server/config/dev.cfg',
		'/vagrant/terrapin_server/config/logging.yaml'
	)
)

@manager.command
def create_db():
	print('Creating Database ... ')
	db.create_all()

@manager.command
def recreate_db():
	print("Dropping Database ... ")
	db.drop_all()
	create_db()

manager.add_command('runserver', Server(host="0.0.0.0", port=8100))

if __name__ == '__main__':
	manager.run()
