
from flask.ext.wtf      import Form
from wtforms            import TextField, TextAreaField
from wtforms.validators import Required


class CreateWorldForm(Form):
	world_name = TextField('World Name', validators = [Required()])


class EditWorldDescriptionForm(Form):
	description = TextAreaField('World Description', validators = [Required()])
