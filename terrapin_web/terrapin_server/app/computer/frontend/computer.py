
from flask            import render_template
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user, login_required

from ..queries        import getWorldsFor
from ..models         import Computer

class ComputerView(FlaskView):
	route_base = '/'

	@route('/world/<string:world_name>/computer/<computer_id>')
	@login_required
	def index(self, world_name, computer_id):
		computer = Computer.query.filter_by(
			owner_id = current_user.id,
			world_name = world_name,
			computer_id = computer_id
		).first()

		if not computer:
			abort(404)

		return render_template('computer/computer.html', computer = computer)
