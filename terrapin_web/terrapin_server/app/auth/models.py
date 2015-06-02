
from uuid import uuid4


from werkzeug        import generate_password_hash, check_password_hash
from flask.ext.login import UserMixin, AnonymousUserMixin


from app      import db
from app.json import JsonSerializableModel

class User(db.Model, UserMixin, JsonSerializableModel):

	__tablename__ = 'user'

	id            = db.Column(db.Integer, primary_key = True)
	user_name     = db.Column(db.String(100), unique = True)
	email         = db.Column(db.String(120), unique = True)
	password_hash = db.Column(db.String(100))
	api_token     = db.Column(db.String(64))

	is_admin      = db.Column(db.Boolean)

	def __init__(self, user_name, email, password, is_admin = False):
		self.user_name = user_name
		self.email     = email
		self.is_admin  = is_admin

		self.set_password(password)

		self.reset_api_token()

	def set_password(self, password):
		self.password_hash = generate_password_hash(password)


	def check_password(self, password):
		return check_password_hash(self.password_hash, password)


	def reset_api_token(self):
		# Generate a uuid and grab the urn (Universal Ressource Name). This has
		# the form:
		#
		# 	>>> uuid4().urn #uniform resource name
		#	'urn:uuid:52f8e1ba-e3ac-11e3-8232-a82066136178'
		#
		# To grab just the uuid part we strip the first 9 characters.

		self.api_token = uuid4().urn[9:]
		return self.api_token


	def __repr__(self):
		return '<User {} (email: {})>'.format(self.user_name, self.email)


	def __str__(self):
		return self.user_name


	def is_active(self):
		""" Returns True if this is an active user. This method is called by the
			login_user method in flask-login. If it returns false the login will
			fail.

			This check can be bypassed by forcing the login (force = True)
		"""
		return True

	@classmethod # TODO: Remember how static methods work
	def from_form(cls, signup_form):
		"""
		Build a user object from form data. This assumes that the the form has
		validated succesfully. No further checks are performed !!!
		"""
		# TODO: Type Annotations !!
		#
		# Importing the SignUpForm causes a circular include chain. Not good !
		# if not isinstance(SignupForm, signup_form):
		# 	raise TypeError(
		# 		'Exected {} for parameter <signu_form>. Got {}' \
		# 		.format(
		# 			type(SignupForm), type(signup_form)
		# 	))

		user = User(
			user_name = signup_form.data['username'],
			email     = signup_form.data['email'],
			password  = signup_form.data['password']
		)
		db.session.add(user)
		db.session.commit()

		return user


class AnonymousUser(AnonymousUserMixin, User):
	"""
	The AnonymousUser class is a simple wrapper around the default
	AnonymousUserMixin that setst the name of the AnonymousUser to
	'Anonymous User'
	"""

	def __init__(self):
		super().__init__('Anonymous User', '', '')
		self.id = 0


	def __repr__(self):
		return '<AnonymousUser>'
