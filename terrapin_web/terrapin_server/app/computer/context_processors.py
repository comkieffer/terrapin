
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
			'target': '#',
			'icon'  : 'globe',
			'children': [
				{ 'label': 'World Properties', 'target': '#' },
				{ 'label': 'Computers',        'target': '#' },
			]
		})

	if current_app.config['DEBUG']:
		menu_items.append({'header': 'Debug Tools'})
		menu_items.append({
			'label' : 'Dev Tools',
			'target': '#',
			'icon'  : 'gears',
			'children': [
				{ 'label': 'Url Map', 'target': url_for('dev.url_map')}
			]
		})

	return { '_menu_items': menu_items}
