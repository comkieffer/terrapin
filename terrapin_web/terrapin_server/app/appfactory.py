
import os, sys, yaml, logging, logging.config

from werkzeug.utils      import import_string
from werkzeug.debug      import DebuggedApplication
from werkzeug.exceptions import default_exceptions, HTTPException

from flask              import Flask, jsonify

from flask_debugtoolbar import DebugToolbarExtension

from .reverse_proxied import ReverseProxied


class NoContextProcessorError(Exception):
	pass

class NoBlueprintError(Exception):
	pass

class AppFactory:

	app_instance = None

	def __init__(self):

		self.flask_config = os.environ.get('FLASK_CONFIG', None)
		if not self.flask_config:
			print(
				'ERROR: The environment variable FLASK_CONFIG is not set. '
				'Unable to locate the appropriate configuration.'
			)
			sys.exit(1)

		self.logging_config_file = os.environ.get('LOGGING_CONFIG', None)
		if not self.logging_config_file:
			print(
				'ERROR: The environment variable LOGGING_CONFIG is not set. '
				'Unable to locate the appropriate logging configuration file.'
			)
			sys.exit(1)

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
		self.logger.debug('Initialised Flask-Debug-Toolbar successfully')

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
		self._register_classy_views()
		self._register_template_filters()
		self._register_context_processors()
		self._load_jinja_extensions()

		# Set up login manager
		from app import login_manager
		from app.auth.models import User, AnonymousUser

		login_manager.init_app(self.app)
		login_manager.login_view     = 'LoginView:index'
		login_manager.anonymous_user = AnonymousUser
		login_manager.user_loader(lambda id:
			User.query.filter_by(id = id).first() )

		self.logger.debug('Login Manager configured.')


		self.logger.debug(
			'Application Initialisation Complete. Ready to serve requests ... ')

		AppFactory.app_instance = self.app

		if self.app.config.get('WRAP_WITH_DEBUGGED_APPLICATION', False):
			self.app = DebuggedApplication(self.app, evalex = True)

		return self.app


	def _make_json_errors(self):
		"""
		Override the default error handlers to return a json object describing
		the error instead of a HTML string.
		"""
		def make_json_error(ex):
			response = jsonify(message = str(ex))
			response.status_code = (
				ex.code if isinstance(ex, HTTPException) else 500)

			return response

		for code in default_exceptions.iter_keys():
			self.app.error_handler_spec[None][code] = make_json_error


	def _get_imported_stuff_by_path(self, path):
		module_name, object_name = path.rsplit('.', 1)
		module = import_string(module_name)

		return module, object_name


	def _register_blueprints(self):
		for blueprint in self.app.config.get('BLUEPRINTS', []):
			if len(blueprint) < 1:
				raise NoBlueprintError('Empty tuple found instead of Blueprint ...')

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


	def _register_classy_views(self):
		""" Load the Flask-Classy based views and register them """

		for view in self.app.config.get('CLASSY_VIEWS', []):
			self.logger.debug('Importing FlaskView: {}'.format(view))
			view_class = import_string(view)
			view_class.register(self.app)


	def _register_context_processors(self):
		for processor_path in self.app.config.get('CONTEXT_PROCESSORS', []):
			module, p_name = self._get_imported_stuff_by_path(processor_path)
			if hasattr(module, p_name):
				self.app.context_processor(getattr(module, p_name))
			else:
				raise NoContextProcessorError('No context processor {} found.'.format(p_name))


	def _load_jinja_extensions(self):
		for extension in self.app.config['JINJA_EXTENSIONS']:
			self.logger.debug('Enabling jinja extension: %s', extension)
			self.app.jinja_env.add_extension(extension)


	def _register_template_filters(self):
		for template_filter in self.app.config['TEMPLATE_FILTERS']:
			self.logger.debug(
				'Registering template filter: <{}> as <{}>'.format(
					template_filter[0], template_filter[1]
			))

			fn = import_string(template_filter[0])
			self.app.add_template_filter(fn, template_filter[1])
