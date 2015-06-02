from flask               import current_app
from flask.ext.script    import Manager, Shell

from app                 import db
from app.appfactory      import AppFactory
from app.auth.models     import User
from app.computer.models import ComputerCheckin

from manage.db        import db_manager
from manage.users     import user_manager
from manage.checkins import checkin_manager


# Set up the environment.
import os
os.environ['FLASK_CONFIG']   = 'app.settings.ShellConfig'
os.environ['LOGGING_CONFIG'] = '/vagrant/terrapin_server/config/logging.yaml'

# Note: We create the main manger with a factory function instead of an app instance
manager = Manager( AppFactory() )

def makeShellContext():
	from app.computer.models import Computer, ComputerCheckin

	return dict(
		# Models
		User            = User,
		Computer        = Computer,
		ComputerCheckin = ComputerCheckin,
	)

@manager.option('-f', '--force', dest='force', required=False)
def bootstrap(force=False):
	from manage.db       import recreate as recreate_db
	from manage.users    import make_users
	from manage.checkins import populate as populate_checkins

	recreate_db(force)
	make_users()
	populate_checkins()


manager.add_command('db', db_manager)
manager.add_command('user', user_manager)
manager.add_command('checkin', checkin_manager)

manager.add_command('shell',
	Shell(make_context = makeShellContext, use_ipython=True))


if __name__ == '__main__':
	manager.run()
