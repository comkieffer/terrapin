
class BaseConfig():
	DEBUG = False

	SECRET_KEY = '2)lx0w2r#u!9#=!r-kd1a25%5-s2odr*81t*kj6s12qnmk$9ix'


	EXTENSIONS = [
	]

	BLUEPRINTS = [
		('app.computer.views.computer', ''),
		('app.computer.api.views.api', '/api'),
		('app.computer.dev.views.dev', '/dev'),
	]

	CONTEXT_PROCESSORS = [
		'app.computer.context_processors.inject_worlds_list',
	]

	# Not Implemented
	TEMPLATE_FILTERS = [
	]

class DevelopmentConfig(BaseConfig):
	DEBUG = True

	SQLALCHEMY_DATABASE_URI = 'sqlite:////vagrant/terrapin_server/app.sqlite'

	DEBUG_TB_PROFILER_ENABLED = True
	DEBUG_TB_INTERCEPT_REDIRECTS = False

class TestingConfig(BaseConfig):
	TESTING = True
	LOGIN_DISABLED = False

	SQLALCHEMY_DATABASE_URI = 'sqlite:////vagrant/eseg-app/test.sqlite'



class ProductionConfig(BaseConfig):
	SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://appadmin:barkingcoweatscrow@localhost/esegapp'
