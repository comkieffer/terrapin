
/*	The CheckinStreamer class listens to the 'new' event produced by a
 * 	CheckinSource and renders the checkin message to display it in the target
 * 	element.
 */

var CheckinStreamer = {
	checkin_count: 0,

	start: function(target) {
		this.target = target;

		target.append('<p>Waiting for checkins ...</p>');
		document.addEventListener('CheckinSource:new', this.onCheckinReceived);
	},

	onCheckinReceived: function(event) {
		var rendered = this.renderCheckin(event.detail.data);

		if (this.checkin_count == 0)
			this.target.clear();

		this.checkin_count += 1;
		target.append(rendered);
	},

	renderCheckin: function(checkin) {
		function render_tmpl(tmpl, data){
			for(var p in data)
				tmpl = tmpl.replace(new RegExp('{'+p+'}','g'), data[p]);
			return tmpl;
		}

		var tmpl =
		'<div class="log-line>'                                                +
		'	<span class="created-at">{created_at}</span>'                      +
		'	<span class="computer-name">{computer_id}: {computer_name}</span>' +
		'	<span class="task-name">{task}</span>'                             +
		'	<span class="{message_class}">{status</span>';

		var data = {
			created_at    : moment.unix(checkin.created_at)
				.format("D MMM YYYY hh:mm"),
			comuter_id    : checkin.computer_id,
			computer_name : checkin.computer_name,
			task          : checkin.task,
			message_class : (checkin.type == 'error')?
				"message bg-danger" : "message"
		}

		return render_tmpl(tmpl, data)
	},
};
