import logging

from flask import Blueprint, request, render_template

from app                  import db
from app.auth.decorators  import admin_required
from app.computer.models  import ComputerCheckin

from .url_map import url_map as gen_url_map


dev = Blueprint('dev', __name__)


@dev.route('/url_map')
@admin_required
def url_map():
	"""
	Inject a flattened url_map into the app that is then added to the page
	javascript so that they can use the endpoint names to generate urls.
	"""

	return render_template('/dev/url_map.html', urls = gen_url_map())
