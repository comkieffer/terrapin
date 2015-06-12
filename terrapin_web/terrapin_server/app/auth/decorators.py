
from functools import wraps

from flask import abort, redirect, url_for
from flask.ext.login import current_user

from app.computer.models import World

def can_view_world(view_fn):
	"""
	Ensure that the user has the correct permissions to view this world.

	Currently that means that the user must be the world owner or an admin. In the
	future we will allow users to share their worlds with friends or even make them
	public.
	"""


	@wraps(view_fn)
	def decorated_fn(world_id, *args, **kwargs):
		if not current_user.is_authenticated():
			return redirect(url_for('LoginView:index'))

		world = World.query.get_or_404(world_id)

		# Only admins and owners should be able to view these pages.
		if not(current_user.is_admin) and not(world.owner_id == current_user.id):
			abort(403)

		return view_fn(world_id, *args, **kwargs)

	return decorated_fn

def admin_required(view_fn):
	"""
	Ensure that the user has the correct permissions to view this world.

	Currently that means that the user must be the world owner or an admin. In the
	future we will allow users to share their worlds with friends or even make them
	public.
	"""


	@wraps(view_fn)
	def decorated_fn(*args, **kwargs):
		if not current_user.is_admin:
			abort(403)

		return view_fn(*args, **kwargs)

	return decorated_fn
