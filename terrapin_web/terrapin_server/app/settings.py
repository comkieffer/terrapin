
class BaseConfig():
	DEBUG = False

	SECRET_KEY = '2)lx0w2r#u!9#=!r-kd1a25%5-s2odr*81t*kj6s12qnmk$9ix'
	SESSION_COOKIE_HTTPONLY = False

	MAX_RECORDS_PER_PAGE = 100

	EXTENSIONS = [
	]

	BLUEPRINTS = [
		('app.dev.views.dev'         , '/dev'),
	]

	CLASSY_VIEWS = [
		'app.auth.views.login:LoginView',
		'app.auth.views.login:LogOutView',
		'app.auth.views.profile:ProfileView',
		'app.auth.views.profile:ChangePasswordView',
		'app.auth.views.profile:RevokeAPITokenView',
		'app.auth.views.signup:SignUpView',

		'app.computer.views.index:IndexView',
		'app.computer.views.world:WorldView',
		'app.computer.views.world:WorldCheckinConfigView',
		'app.computer.views.world:CreateNewWorldView',
		'app.computer.views.world:EditWorldDescriptionView',
		'app.computer.views.computer:ComputerView',
		'app.computer.views.config:CheckinConfigView',
		'app.computer.views.checkin:MakeCheckinView',

		'app.computer.api.checkin:CheckinView',
		'app.computer.api.views:APIWorldView',
		'app.computer.api.views:APIComputersView',
	]

	CONTEXT_PROCESSORS = [
		'app.computer.context_processors.inject_worlds_list',
		'app.computer.context_processors.inject_menu_items',
	]

	# Not Implemented
	TEMPLATE_FILTERS = [
		('app.template_filters:pluralize'      , 'pluralize'),
		('app.template_filters:datetimeformat' , 'datetime'),
		('app.template_filters:make_time'      , 'time'),
		('app.template_filters:make_date'      , 'date'),
		('app.template_filters:prettify_date'  , 'prettify_date'),
		('app.template_filters:constrain'      , 'constrain'),
		('app.template_filters:tick2mctime'    , 'mcTime'),
	]

	JINJA_EXTENSIONS = [
		'jinja2.ext.do',
	]


class DevelopmentConfig(BaseConfig):
	DEBUG = True
	WRAP_WITH_DEBUGGED_APPLICATION = True

	SQLALCHEMY_DATABASE_URI = 'sqlite:////vagrant/terrapin_server/app.sqlite'

	DEBUG_TB_PROFILER_ENABLED = True
	DEBUG_TB_INTERCEPT_REDIRECTS = False


class ShellConfig(DevelopmentConfig):
	"""
	The shell config overrides the WRAP_WITH_DEBUGGED_APPLICATION since it occludes the
	test_request_context which we need to run the 'shell' mode in Flask-Script
	"""
	WRAP_WITH_DEBUGGED_APPLICATION = False


class TestingConfig(BaseConfig):
	TESTING = True
	LOGIN_DISABLED = False

	# We don't need csrf when running automated tests.
	WTF_CSRF_ENABLED       = False
	WTF_CSRF_CHECK_DEFAULT = False

	SQLALCHEMY_DATABASE_URI = 'sqlite:///memory'


class ProductionConfig(BaseConfig):
	SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://appadmin:barkingcoweatscrow@localhost/esegapp'
