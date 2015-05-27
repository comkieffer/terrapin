
/*	The CheckinStreamer class listens to the 'new' event produced by a
 * 	CheckinSource and renders the checkin message to display it in the target
 * 	element.
 */

var CheckinStreamer = {

	start: function(target) {
		var self = this;
		self.target = target;

		target.append('<p>Waiting for checkins ...</p>');
		document.addEventListener('CheckinSource:new', onCheckinReceived);
	},

	onCheckinReceived: function(event) {
		var rendered = self.render(event.detail.data);
		target.append(rendered);
	},

	renderCheckin: function(checkin) {
		return 'TODO';
	},
};
