
from flask               import render_template, redirect, url_for, request
from flask.ext.classy    import FlaskView, route
from flask.ext.login     import current_user

from app                 import pastebin, db
from app.auth.decorators import can_view_world

from ..queries           import getWorldsFor
from ..models            import World
from ..forms             import CreateWorldForm
from ..utils             import makeCheckinConfig

class WorldView(FlaskView):
	route_base = '/'
	decorators = [can_view_world]

	@route('/world/<int:world_id>')
	def index(self, world_id):
		world = World.query.get_or_404(world_id)

		return render_template('computer/world.html', world = world)



		checkin_cfg_tpl = (
			"return  {                               \n"
			"	['World Name'] = '{{ world_name }}', \n"
			"	['Server URL'] = '{{ server_url }}', \n"
			"	['API Token']  = '{{ api_token }}',  \n"
			"}                                       \n"
		)

		checkin_cfg = render_template_string(checkin_cfg_tpl,
			world_name = world.name, server_url = 'localhost',
			api_token = current_user.api_token
		)

class WorldCheckinConfigView(FlaskView):
	route_base = '/'
	decorators = [can_view_world]

	@route('/world/<int:world_id>/checkin-configuration')
	def index(self, world_id):
		world = World.query.get_or_404(world_id)
		checkin_cfg = makeCheckinConfig(world.name, current_user)

		if not world.pastebin_code or request.args.get('force'):
			url, code = pastebin.paste(checkin_cfg,
				title = 'Checkin Configuration for ' + world.name,
				privacy = 'unlisted',
				expiration = '1M',
				format = 'lua',
			)

			world.pastebin_url  = url
			world.pastebin_code = code
			db.session.commit()

		return render_template('computer/checkin_config.html',
			world = world, checkin_cfg = checkin_cfg)

class CreateNewWorldView(FlaskView):
	route_base = '/world/create'

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

