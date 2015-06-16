
/*	The CheckinStreamer class listens to the 'new' event produced by a
 * 	CheckinSource and renders the checkin message to display it in the target
 * 	element.
 */

function CheckinStreamer(target) {
	this.target = target;
	target.append('<p>Waiting for checkins ...</p>');

	return this;
}

CheckinStreamer.prototype = {
	checkin_count: 0,

	start: function(target) {
		var self = this;

		document.addEventListener('CheckinSource:new',
			$.proxy(this.onCheckinReceived, this));
	},

	onCheckinReceived: function(event) {
		console.log(event)
		var rendered = this.renderCheckin(event.detail);

		if (this.checkin_count == 0)
			this.target.empty();

		this.checkin_count += 1;
		this.target.append(rendered);
	},

	renderCheckin: function(checkin) {
		function render_tmpl(tmpl, data){
			for(var key in data) {
				tmpl = tmpl.replace(new RegExp('{'+ key +'}','g'), data[key]);
			}
			return tmpl;
		}

		var tmpl =
		'<div class="log-line">'                                                +
		'	<span class="created-at">{created_at}</span>'                      +
		'	<span class="computer-name">'                                      +
		'		[Id: {computer_id}] {computer_name}</span>'                    +
		'	<span class="task-name">{task}</span>'                             +
		'	<span class="{message_class}">{status}</span>'                     +
		'</div>'                                                               ;

		var data = {
			created_at    : moment.unix(checkin.created_at)
				.format("D MMM YYYY hh:mm"),
			computer_id    : checkin.computer_id,
			computer_name : checkin.computer_name,
			task          : checkin.task,
			message_class : (checkin.type == 'error')?
				"message bg-danger" : "message",
			status        : checkin.status
		}

		return render_tmpl(tmpl, data)
	},
};
