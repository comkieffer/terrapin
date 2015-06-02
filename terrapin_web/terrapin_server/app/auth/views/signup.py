
from flask            import render_template, url_for, redirect
from flask.ext.classy import FlaskView
from flask.ext.login  import login_user

from ..forms   import SignUpForm
from ..signals import NewUserRegistered
from ..models  import User

class SignUpView(FlaskView):

	def index(self):
		return render_template('auth/signup.html', form = SignUpForm())


	def post(self):
		signup_form = SignUpForm()

		if signup_form.validate_on_submit():
			new_user = User.from_form(signup_form)
			NewUserRegistered.send('SignUpView', user = new_user)

			login_user(new_user)
			return redirect(url_for('IndexView:index'))

		else:
			return render_template('auth/signup.html', form = signup_form)
