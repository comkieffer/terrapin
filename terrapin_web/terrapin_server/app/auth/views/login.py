
from flask            import request, redirect, url_for, render_template
from flask.ext.classy import FlaskView
from flask.ext.login  import current_user, login_user, logout_user

from ..forms  import LoginForm
from ..models import User

class LoginView(FlaskView):

	def index(self):
		if current_user.is_authenticated():
			print(current_user)
			return redirect(
				request.args.get('next') or url_for('IndexView:index')
			)

		return render_template('auth/login.html', form = LoginForm())

	def post(self):
		login_form = LoginForm()

		if login_form.validate_on_submit():
			user = User.query.filter_by(
				user_name = login_form.data['user_name']).one()

			# If the form validates we can log in
			if login_user(user):
				# TODO: Handle remember me value
				# TODO: Log action - logged in

				return redirect(
					request.args.get('next') or url_for('IndexView:index')
				)
			else:
				# We were unable to log the user in for some reason - A better
				# error message would be nice

				# TODO: Log action - login failed (IP = ip_address = request.remote_addr)

				return render_template('auth/unauthorized.html')

		else:
			print('Failed Validation')
			print(login_form.errors)
			return render_template('auth/login.html', form = login_form)


class LogOutView(FlaskView):

	def index(self):
		logout_user()

		return redirect(url_for('IndexView:index'))

