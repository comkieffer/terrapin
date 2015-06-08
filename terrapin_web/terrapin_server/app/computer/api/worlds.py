
from flask            import jsonify, abort
from flask.ext.login  import current_user
from flask.ext.classy import FlaskView

from app.auth.models  import User

from ..queries import getWorldsFor
from ..models  import Computer, World


class APIWorldView(FlaskView):
	route_base = '/api/user/<int:user_id>/world'



	def index(self, user_id):
		# Only the owner of the world should be allowed to query this.
		# At the moment we use cookies for auth. This isn't the best idea since
		# it makes it harder to write clients.
		# It only works because the API is only called from the browser
		if not (current_user.is_admin or current_user.id == user_id):
			abort(403)

		user = User.query.get_or_404(user_id)
		worlds = getWorldsFor(user)

		return jsonify({'data': worlds})


	def get(self, user_id, world_id):
		if not (current_user.is_admin or current_user.id == user_id):
			abort(403)

		user = User.query.get_or_404(user_id)
		world = World.query.get_or_404(world_id)

		return jsonify({'data': world})

class APIComputersView(FlaskView):
	route_base = '/api/user/<int:user_id>/world/<int:world_id>/computer'

	def index(self, user_id, world_id):
		if not (current_user.is_admin or current_user.id == user_id):
			abort(403)

		world = World.query.get_or_404(world_id)

		return jsonify({'data': world.devices})

	def get(self, user_id, world_id, computer_id):
		if not (current_user.is_admin or current_user.id == user_id):
			abort(403)

		world = World.query.get_or_404(world_id)
		computer = Computer.query.get_or_404(computer_id)

		if not(current_user.is_admin or current_user.id == computer.owner_id):
			abort(403)

		return jsonify({'data': computer})
