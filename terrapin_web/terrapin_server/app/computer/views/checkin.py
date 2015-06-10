
from flask               import render_template
from flask.ext.classy    import FlaskView

from app.auth.models     import User
from app.auth.decorators import admin_required

class MakeCheckinView(FlaskView):
	route_base = '/checkin/'
	decorators = [admin_required]

	def index(self):
		return render_template('computer/make_checkin.html', users = User.query.all())
