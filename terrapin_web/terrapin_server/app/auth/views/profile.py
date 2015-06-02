from flask            import render_template, redirect, url_for
from flask.ext.classy import FlaskView
from flask.ext.login  import current_user, login_required

from ..forms   import ChangePasswordForm
from ..signals import PasswordChanged

class ProfileView(FlaskView):

	@login_required
	def index(self, user_id):
		return render_template('auth/profile.html')


class ChangePasswordView(FlaskView):

	def index(self):
		return render_template('auth/change_password.html', form = ChangePasswordForm())

	def post(self):
		change_password_form = ChangePasswordForm()

		if change_password_form.validate_on_submit():
			current_user.set_password(change_password_form.data['new_password'])
			PasswordChanged('ChangePasswordView', user = current_user)

			return redirect(url_for('ProfileView:index'))

		else:
			return render_template('auth/change_password.html', form = change_password_form)


class RevokeAPITokenView(FlaskView):

	def index(self):
		current_user.reset_api_token()
		return redirect( url_for('ProfileView:index') )
