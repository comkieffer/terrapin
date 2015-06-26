
from flask            import render_template
from flask            import render_template, current_app, jsonify
from flask.ext.classy import FlaskView, route
from flask.ext.login  import current_user

from app.auth.decorators import can_view_world

from ..queries        import getWorldsFor, getTaskFrequenciesFor
from ..models         import Computer

class ComputerView(FlaskView):
	route_base = '/'
	decorators = [can_view_world]

	@route('/world/<int:world_id>/computer/<computer_id>')
	def index(self, world_id, computer_id):
		computer = Computer.query.filter_by(
			parent_world_id = world_id,
			computer_id = computer_id
		).first()

		if not computer:
			abort(404)

		return render_template('computer/computer.html',
			computer = computer, tasks = getTaskFrequenciesFor(computer)[:5])


class ComputerCheckinsView(FlaskView):
	route_base = '/world/<int:world_id>/computer/<int:computer_id>/checkins'

	def _getPage(self, computer, page):
		return computer.checkins                                            \
			.order_by(ComputerCheckin.created_at.desc())                   \
			.paginate(1, current_app.config['PAGINATION_RECORD_PER_PAGE'])


	def index(self, world_id, computer_id):
		return self.get(world_id, computer_id, 1)


	@route('/page/<int:page>')
	def get(self, world_id, computer_id, page):
		computer = getComputer(world_id, computer_id)
		if not computer:
			abort(404)

		return jsonify(
			{ 'data': self._getPage(computer, page).items }
		)

