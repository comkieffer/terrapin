

function NotificationStreamer() {
	return this
}

NotificationStreamer.prototype = {
	event_processors: [
		function(parent, checkin) {
			if (checkin['message_type'] == 'error')
				parent.notify('Error', checkin['status'], 'error');
		},

		function(parent, checkin) {
			if (checkin['message_type'] == 'task-end')
				parent.notify('Task Finished', checkin['status'], 'info');
		},
	],

	start: function() {
		console.log('Notification streamer is listening for events ...')
		document.addEventListener('CheckinSource:new',
			$.proxy(this.onCheckinReceived, this));
	},

	onCheckinReceived: function(event) {
		var checkin = event['detail'];
		var self = this;

		console.log('NotificationStreamer received event: ', checkin)

		$.each(this.event_processors, function(i, process) {
			process(self, checkin);
		});
	},

	/*
	 * @param type: One of ['info', 'success', 'error']
	 */
	notify: function(title, message, type) {
		function render_tmpl(tmpl, data){
			for(var key in data) {
				tmpl = tmpl.replace(new RegExp('{'+ key +'}','g'), data[key]);
			}
			return tmpl;
		}

		var message_tmpl =
			'<h4>{title}</h4>' +
			'<p>{message}</p>' ;

		Messenger().post({
			message: render_tmpl(message_tmpl, {title: title, message: message}),
			type: type
		});
	},
}
