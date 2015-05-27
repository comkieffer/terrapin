
from flask            import render_template
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user, login_required

from ..queries        import getWorldsFor
from ..models         import World

class WorldView(FlaskView):
	route_base = '/'

	@route('/world/<string:world_name>')
	@login_required
	def index(self, world_name):
		try:
			world = World(world_name, current_user)
		except RuntimeError as Ex:
			abort(403)

		return render_template('computer/world.html', world = world)
