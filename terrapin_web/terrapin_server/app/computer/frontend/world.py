
from flask            import render_template
from flask.ext.classy import FlaskView, route

from app.auth.decorators import can_view_world


from ..queries        import getWorldsFor
from ..models         import World

class WorldView(FlaskView):
	route_base = '/'
	decorators = [can_view_world]

	@route('/world/<int:world_id>')
	def index(self, world_id):
		world = World.query.get_or_404(world_id)

		return render_template('computer/world.html', world = world)
