
function Turtle(data) {
	this.turtleName = ko.observable("data.name");
}


function TurtleViewModel() {
	var self = this;

	self.turtles = ko.observableArray([]);

	$.getJSON("/api/computer/all", function(allData) {
		console.log(allData['data'])
		self.turtles(allData['data']);
	});
}

ko.applyBindings(new TurtleViewModel());
