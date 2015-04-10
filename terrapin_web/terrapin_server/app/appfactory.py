
import os, sys, yaml, logging, logging.config

from werkzeug.utils import import_string
from werkzeug.debug import DebuggedApplication

from flask              import Flask

from flask_debugtoolbar import DebugToolbarExtension

from .reverse_proxied import ReverseProxied


class NoContextProcessorError(Exception):
	pass

class NoBlueprintError(Exception):
	pass

class AppFactory:

	def __init__(self):

		self.flask_config = os.environ.get('FLASK_CONFIG', None)
		if not self.flask_config:
			print(
				'ERROR: The environment variable FLASK_CONFIG is not set. '
				'Unable to locate the appropriate configuration.'
			)
			sys.exit(0)

		self.logging_config_file = os.environ.get('LOGGING_CONFIG', None)
		if not self.logging_config_file:
			print(
				'ERROR: The environment variable LOGGING_CONFIG is not set. '
				'Unable to locate the appropriate logging configuration file.'
			)
			sys.exit(0)

	def __call__(self):

		with open(self.logging_config_file, 'r') as cfg_file:
			config = yaml.safe_load(cfg_file)
			logging.config.dictConfig(config)

		self.logger = logging.getLogger(__name__)
		self.logger.debug('Loaded logger configuration successfully.')

		self.logger.debug('Application configuration: %s', self.flask_config)
		self.logger.debug('Logging configuration: %s', self.logging_config_file)

		## Initialize the app and load it's configurations
		self.app = Flask(__name__.split('.')[0])
		self.app.wsgi_app = ReverseProxied(self.app.wsgi_app)

		self.app.config.from_object(self.flask_config)
		self.logger.debug('Loaded configuration successfully.')

		self.toolbar = DebugToolbarExtension(self.app)
		self.logger.debug('Loaded Flask-Debug-Toolbar successfully')

		## Initialise apps:
		# Set up SQLALchemy. Make sure that the database file app.db exists before
		# running. If it doesn't exist run 'python create_db.py' to create it
		from app import db
		db.init_app(self.app)
		self.logger.debug('Initialised SQLAlchemy successfully')

		# Set the JSONEncoder we use :
		from app.json import CustomJSONEncoder
		self.app.json_encoder = CustomJSONEncoder

		self._register_blueprints()
		self._register_template_filters()
		self._register_context_processors()

		self.logger.debug(
			'Application Initialisation Complete. Ready to serve requests ... ')
		
		if self.app.config['DEBUG']:
			self.app = DebuggedApplication(self.app, evalex = True)
			
		return self.app


	def _get_imported_stuff_by_path(self, path):
		module_name, object_name = path.rsplit('.', 1)
		module = import_string(module_name)

		return module, object_name


	def _register_blueprints(self):
		for blueprint in self.app.config.get('BLUEPRINTS', []):
			if len(blueprint) < 1:
				raise NoBlueprintError('Emty tuple found instead of Blueprint ...')

			module, bp_name = self._get_imported_stuff_by_path(blueprint[0])
			if hasattr(module, bp_name):
				if len(blueprint) > 1 and blueprint[1] != '':
					self.app.register_blueprint(getattr(module, bp_name), url_prefix = blueprint[1])
					self.logger.debug('Loaded blueprint <%s> with url_prefix = %s', blueprint[0], blueprint[1])
				else:
					self.app.register_blueprint(getattr(module, bp_name))
					self.logger.debug('Loaded blueprint <%s> with url_prefix = /', blueprint[0])

			else:
				raise NoBlueprintError('No blueprint {} found.'.format(bp_name))

	def _register_context_processors(self):
		for processor_path in self.app.config.get('CONTEXT_PROCESSORS', []):
			module, p_name = self._get_imported_stuff_by_path(processor_path)
			if hasattr(module, p_name):
				self.app.context_processor(getattr(module, p_name))
			else:
				raise NoContextProcessorError('No context processor {} found.'.format(p_name))

	def _register_template_filters(self):
		from .template_filters import register_filters
		register_filters(self.app)
