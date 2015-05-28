
from flask            import render_template
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user, login_required

from ..queries        import getWorldsFor
from ..models         import Computer

class ComputerView(FlaskView):
	route_base = '/'

	@route('/world/<int:world_id>/computer/<computer_id>')
	@login_required
	def index(self, world_id, computer_id):
		computer = Computer.query.filter_by(
			parent_world_id = world_id,
			computer_id = computer_id
		).first()

		if not computer:
			abort(404)

		return render_template('computer/computer.html', computer = computer)
