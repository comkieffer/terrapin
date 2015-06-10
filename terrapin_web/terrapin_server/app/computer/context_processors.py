
from flask           import current_app, url_for
from flask.ext.login import current_user

from .queries        import getWorldsFor

def inject_worlds_list():
	return { '_worlds': getWorldsFor(current_user) }


def inject_menu_items():
	menu_items = [
		{'header': 'My Worlds'}
	]

	for world in getWorldsFor(current_user):
		menu_items.append({
			'label' : world.name,
			'target': url_for('WorldView:index', world_id = world.id),
			'icon'  : 'globe',
		})

	menu_items.extend([
		{ 'header': 'Tools' },
		{
			'label': 'Create New World',
			'target': url_for('CreateNewWorldView:index'),
			'icon': 'gears',
		}
	])

	if current_app.config['DEBUG']:
		menu_items.extend([
			{ 'header': 'Debug Tools' },
			{
				'label' : 'Url Map',
				'target': url_for('dev.url_map'),
				'icon'  : 'globe',
			}, {
				'label' : 'Make Checkins',
				'target': url_for('MakeCheckinView:index'),
				'icon'  : 'plus-square',
			}
		])

	return { '_menu_items': menu_items}
