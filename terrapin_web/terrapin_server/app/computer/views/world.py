
import logging

from flask               import render_template, redirect, url_for, request
from flask.ext.classy    import FlaskView, route
from flask.ext.login     import current_user, login_required

from app                 import pastebin, db
from app.auth.decorators import can_view_world

from ..queries           import getWorldsFor
from ..models            import World, CheckinConfig
from ..forms             import CreateWorldForm, EditWorldDescriptionForm
from ..utils             import makeCheckinConfig

class WorldView(FlaskView):
	route_base = '/world/<int:world_id>'
	decorators = [can_view_world]

	def index(self, world_id):
		world = World.query.get_or_404(world_id)

		return render_template('computer/world.html', world = world)


class CreateNewWorldView(FlaskView):
	route_base = '/world/create'

	decorators = [login_required]

	def index(self):
		form = CreateWorldForm()

		return render_template('computer/create_world.html', form = form)


	def post(self):
		form = CreateWorldForm()

		if form.validate_on_submit():
			new_world = World(form.data['world_name'], current_user)
			db.session.add(new_world)
			db.session.commit()

			return redirect(
				url_for('WorldView:index', world_id = new_world.id))

		else:
			return render_template('computer/create_world.html', form = form)


class WorldCheckinConfigView(FlaskView):
	route_base = '/world/<int:world_id>/checkin-configuration'
	decorators = [can_view_world]

	def index(self, world_id):
		logger = logging.getLogger(__name__)

		world = World.query.get_or_404(world_id)

		# If we have an old checkin configuration we need to destroy it.
		if world.config and request.args.get('force'):
			logger.info('Deleting checkin configuration for world: %r', world)
			db.session.delete(world.config)
			world.config = None

		# Create the world config
		if not world.config:
			config = CheckinConfig(makeCheckinConfig(world.name, current_user))
			db.session.add(config)
			db.session.commit()

			world.config = config
			logger.info(
				'Creating world configuration for world %r. CheckinConfig: %r' %
				(world, config)
			)
			db.session.commit()

		return render_template('computer/checkin_config.html', world = world)


# TODO: Form default arameters
class EditWorldDescriptionView(FlaskView):
	route_base = '/world/<int:world_id>/description'

	decorators = [can_view_world]

	def index(self, world_id):
		# Make sure that the world exists
		World.query.get_or_404(world_id)

		form = EditWorldDescriptionForm()
		return render_template('computer/edit_world_description.html', form = form)


	def post(self, world_id):
		form = EditWorldDescriptionForm()

		if form.validate_on_submit():
			world = World.query.get_or_404(world_id)
			world.description = form.data['description']
			db.session.commit()

			return redirect(url_for('WorldView:index', world_id = world_id))

		else:
			return render_template('computer/edit_world_description.html', form = form)
