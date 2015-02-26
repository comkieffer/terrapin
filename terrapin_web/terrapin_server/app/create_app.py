import logging, logging.config, yaml,os

from flask import Flask

from .reverse_proxied import ReverseProxied

def create_app(config_file, logging_config):

	with open(logging_config, 'r')  as cfg_file:
		config = yaml.safe_load(cfg_file)
		logging.config.dictConfig(config)

	logger = logging.getLogger(__name__)
	logger.debug('Loaded logger configuration successfully.')

	## Initialize the app and load it's configurations
	app = Flask(__name__.split('.')[0])
	app.wsgi_app = ReverseProxied(app.wsgi_app)

	# Generate the path and load the configuration
	logger.debug('Loading configuration file %s', config_file)

	app.config.from_pyfile(config_file)

	#
	# We now have a good app running
	# 	We can start loading blueprints and extensions
	#
	logger.debug('Loading SQLAlchemy databse with URI : {}' \
		.format(app.config['SQLALCHEMY_DATABASE_URI'])
	)

	from app import db
	db.init_app(app)
	logger.debug('Initialised SQLAlchemy successfully')

	# Set up Flask-DebugToolbar. If DEBUG is on then the toolbar will be inject into
	# the templates automatically
	from flask_debugtoolbar import DebugToolbarExtension

	toolbar = DebugToolbarExtension(app)
	logger.debug('Loaded Flask-Debug-Toolbar successfully')

	## Register our extra template filters
	from .template_filters import register_filters
	register_filters(app)
	logger.debug('template filters loaded successfully.')

	# load the application blueprints
	from app.computer.views import computer
	app.register_blueprint(computer)

	from app.computer.api import api
	app.register_blueprint(api, url_prefix = '/api')

	# Set the JSONEncoder we use :
	from app.json import CustomJSONEncoder
	app.json_encoder = CustomJSONEncoder

	return app
