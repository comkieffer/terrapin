

var Checkin = React.createClass({
  render: function() {
    // TODO : Add error class if needed (if type == "error")
    // TODO: Format Time

    var formatted_created_at =
      moment.unix(this.props.checkin.created_at)
        .format("D MMM YYYY hh:mm");

    var message_class = (this.props.checkin.type == "error") ?
      "message bg-danger" : "message";

    var computer_id_name = "[" + this.props.checkin.computer_id + "]" +
      this.props.checkin.computer_name;

    return (
      <div className = "log-line">
        <span>
          { formatted_created_at }</span>
        <span className = "computer-name">
          { computer_id_name }
        </span>
        <span className = "task-name">
          {  this.props.checkin.task }</span>

        <span className = { message_class }>
          {  this.props.checkin.status }</span>
      </div>
    );
  }
});

var CheckinList = React.createClass({
  getInitialState: function() {
    return { checkins: [] }
  },

  componentDidMount: function() {
    var CheckinSocket = new WebSocket('ws://localhost:8100/checkin/stream');
    var self = this;

    CheckinSocket.onmessage = function(event) {
      self.setState({
        checkins: self.state.checkins.concat($.parseJSON(event.data))
      });
    }
  },

  render: function() {
    var checkins = this.state.checkins.map(function(item) {
      return (
        <Checkin key={item.id} checkin={item} />
      );
    });

    return (
      <div className = "checkin-list">
        {checkins}
      </div>
    );
  }
});


React.render(
  <CheckinList />,
  document.getElementById("content")
);
