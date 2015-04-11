
var Checkin = React.createClass({
  render: function() {
    // TODO : Add error class if needed (if type == "error")
    // TODO: Format Time
    // console.log('Checkinitem:', this.props.checkin);

    var formatted_created_at =
      moment.unix(this.props.checkin.created_at)
        .format("D MMM YYYY hh:mm");

    var message_class = (this.props.checkin.type == "error") ?
      "message bg-danger" : "message";

    var computer_id_name = "[" + this.props.checkin.computer_id + "]" +
      this.props.checkin.computer_name;

    return (
      <div className = "log-line clearfix">
        <span className = "created-at">
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