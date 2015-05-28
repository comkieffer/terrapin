
from flask            import render_template
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user, login_required

from ..queries        import getWorldsFor
from ..models         import World

class WorldView(FlaskView):
	route_base = '/'

	@route('/world/<int:world_id>')
	@login_required
	def index(self, world_id):
		world = World.query.get_or_404(world_id)

		return render_template('computer/world.html', world = world)
