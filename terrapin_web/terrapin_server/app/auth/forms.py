
from flask.ext.wtf      import Form
from wtforms            import TextField, BooleanField, PasswordField, SubmitField
from wtforms.validators import Required, Email

from .models import User


class LoginForm(Form):
	user_name   = TextField('User Name', validators = [Required()])
	password    = PasswordField('Password', validators = [Required()])
	remember_me = BooleanField('Remember me', default = False)

	def __init__(self, *args, **kwargs):
		Form.__init__(self, *args, **kwargs)

	def validate(self):
		if not super().validate():
			return False

		# Load the user and check the password hash
		user = User.query.filter_by(user_name = self.data['user_name']).first()
		if user and user.check_password(self.password.data):
			return True
		else:
			self.user_name.errors.append('Invalid user name or password')
			return False


class SignUpForm(Form):
	username         = TextField('User Name', validators = [Required()])
	email            = TextField('Email Address', validators = [Required(), Email()])
	password         = PasswordField('Password', validators = [Required()])
	password_confirm = PasswordField('Confirm Password', validators = [Required()])
	submit           = SubmitField()

	def __init__(self, *args, **kwargs):
		Form.__init__(self, *args, **kwargs)

	def validate(self):
		""" Check that the form is valid.

			A valid User must have a unique username and email.

			@return True if the user is unique, False otherwise
		"""
		if not Form.validate(self):
			return False

		if self.password.data != self.password_confirm.data:
			self.password.errors.append('The 2 passwords do not match')
			return False

		user = User.query.filter_by(email = self.email.data.lower()).first()
		if user:
			self.email.errors.append(
				'A user account with this email already exists')
			return False

		user = User.query.filter_by(user_name = self.username.data.lower()).first()
		if user:
			self.username.errors.append(
				'A user account with this user name already exists')
			return False

		# Everything Ok. We can create the account
		return True


class ChangePasswordForm(Form):

	current_password    = PasswordField('Password',            validators = [Required()])
	new_password        = PasswordField('New Password',        validators = [Required()])
	new_password_repeat = PasswordField('Repeat New Password', validators = [Required()])

	def validate():
		"""
		Validate the ChangePasswordForm.

		The validation logic is trivial. We simply make sure that the 2 values
		for the new password match adn that the old password is corrrect.
		"""

		if not super().validate():
			return False

		if self.data['new_password'] != self.data['new_password_repeat']:
			self.new_password.errors.append(
				'The passwords do not match !'
			)
			return False

		if not current_user.check_password(self.data['password']):
			self.password.errors.append('Invalid Password')
			return False

		return True
