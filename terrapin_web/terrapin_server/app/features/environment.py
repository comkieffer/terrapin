
import os, sys

# Add the app directory to the python path:
sys.path.append('/vagrant/terrapin_server/')

from app             import db
from app.appfactory  import AppFactory
from app.auth.models import User

def before_feature(context, feature):
	"""
	Make sure that the app is correctly set up.

	We need:
		- To use the Testing configuration,
		- To use a clean database,
		- To attach a test client,
		- To a create a user to log-in as
	"""

	os.environ['FLASK_CONFIG']   = 'app.settings.TestingConfig'
	os.environ['LOGGING_CONFIG'] = '/vagrant/terrapin_server/config/logging_test.yaml'

	context.db      = db
	context.app     = AppFactory()()
	context.client  = context.app.test_client()
	context.app_ctx = context.app.test_request_context()

	# Push the context. This allows us to access all the context globals we
	# need. Namely the model objects (Use.query. ...), url_for, and other
	# goodies
	context.app_ctx.push()

	db.create_all()


def after_feature(context, feature):
	db.drop_all()

	# Remember to clear the application context:
	context.app_ctx.pop()
