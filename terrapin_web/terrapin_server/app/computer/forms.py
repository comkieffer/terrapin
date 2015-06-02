
from flask.ext.wtf      import Form
from wtforms            import TextField
from wtforms.validators import Required


class CreateWorldForm(Form):
	world_name = TextField('World Name', validators = [Required()])
