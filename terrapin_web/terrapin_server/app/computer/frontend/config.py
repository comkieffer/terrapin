
from flask            import make_response
from flask.ext.classy import FlaskView

from ..models import CheckinConfig

class CheckinConfigView(FlaskView):
	route_base = '/config/'

	def get(self, config_id):
		config = CheckinConfig.query          \
			.filter_by(id_string = config_id) \
			.first_or_404()

		return make_response(config.config)

