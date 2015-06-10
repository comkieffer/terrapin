
from flask            import render_template
from flask.ext.login  import login_required
from flask.ext.classy import FlaskView

from app.auth.models import User

class MakeCheckinView(FlaskView):
	route_base = '/checkin/'
	decorators = [login_required]

	def index(self):
		return render_template('computer/make_checkin.html', users = User.query.all())
