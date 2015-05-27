
from flask            import render_template
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user, login_required

from ..queries        import getWorldsFor

class IndexView(FlaskView):
	route_base = '/'

	@login_required
	def index(self):
		return render_template('computer/index.html')
