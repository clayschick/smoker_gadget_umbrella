// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import { Socket } from "phoenix"

// let socket = new Socket("/socket", {params: {token: window.userToken}})
let socket = new Socket("/socket")

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("pid:control", {})

// PID Controller variables that will be represented on the graph
let input = 0
let setpoint = 0
let output = 0
let kp = 0
let ki = 0
let kd = 0

//// Setpoint Control
let setpointInput = document.querySelector("#setpoint-input")

// Push the updated setpoint to the server
setpointInput.addEventListener("keypress", event => {
  if (event.keyCode === 13) {
    setpoint = setpointInput.value
    channel.push("setpoint_update", { setpoint: setpointInput.value })
  }
})

// Receive the updated setpoint from the server
// channel.on("setpoint_updated", payload => {
//   setpoint = payload.setpoint
// })

//// Output Control  
let outputInput = document.querySelector("#output")

// Receive the updated output from the server
// channel.on("output_updated", payload => {
//   output = payload.output
//   outputInput.value = payload.output
// })

//// KP Control
let kpInput = document.querySelector("#KP")

kpInput.addEventListener("keypress", event => {
  if (event.keyCode === 13) {
    channel.push("kp_update", { kp: kpInput.value })
  }
})

//// KI Control
let kiInput = document.querySelector("#KI")

kiInput.addEventListener("keypress", event => {
  if (event.keyCode === 13) {
    channel.push("ki_update", { ki: kiInput.value })
  }
})

//// KD Control
let kdInput = document.querySelector("#KD")

kdInput.addEventListener("keypress", event => {
  if (event.keyCode === 13) {
    channel.push("kd_update", { kd: kdInput.value })
  }
})

//// Input Control
let inputInput = document.querySelector("#input")

// Push the updated input value to the server
inputInput.addEventListener("keypress", event => {
  if (event.keyCode === 13) {
    channel.push("input_update", { input: inputInput.value })
  }
})

//// Start and Stop buttons
// let startButton = document.querySelector("#start")
// let stopButton = document.querySelector("#stop")
let autoToggle = document.querySelector("#auto-toggle")

autoToggle.addEventListener("change", event => {
  if(event.target.checked) {
    setpoint = setpointInput.value
    channel.push("start_controller", {
      setpoint: setpointInput.value, 
      kp: kpInput.value, 
      ki: kiInput.value, 
      kd: kdInput.value
    })
  } else {
    channel.push("stop_controller", {})
  }
})

// startButton.addEventListener("click", event => {
//   setpoint = setpointInput.value
//   channel.push("start_controller", {setpoint: setpointInput.value, kp: kpInput.value, ki: kiInput.value, kd: kdInput.value})
// })

// stopButton.addEventListener("click", event => {
//   channel.push("stop_controller", {})
// })

// Receive the updated input valuesfrom the server
channel.on("input_updated", payload => {
  console.log("got input", payload.input)
  input = payload.input
  inputInput.value = input
})

// Receive the updated input and output values from the server
channel.on("controller_updated", payload => {
  output = payload.output
  outputInput.value = output
  input = payload.input
  inputInput.value = input

  var current_time = Date.now()

  // Update the setpoint control
  chart.config.data.datasets[0].data.push({ x: current_time, y: setPointValue() })

  // Update the output control
  chart.config.data.datasets[1].data.push({ x: current_time, y: payload.input })

  // update chart datasets keeping the current animation
  chart.update({
      preservation: true
  });
})

// Chart - need to move all this to it's own module
var chartColors = {
	red: 'rgb(255, 99, 132)',
	orange: 'rgb(255, 159, 64)',
	yellow: 'rgb(255, 205, 86)',
	green: 'rgb(75, 192, 192)',
	blue: 'rgb(54, 162, 235)',
	purple: 'rgb(153, 102, 255)',
	grey: 'rgb(201, 203, 207)'
};

var color = Chart.helpers.color

var ctx = document.getElementById('myChart').getContext('2d');

function setPointValue() {
  return setpoint
}

function outputValue() {
  return output
}

function inputValue() {
  return input
}

function kpValue() {
  return kp
}

function kiValue() {
  return ki
}

function kdValue() {
  return kd
}

var chart = new Chart(ctx, {
  type: 'line',
  data: {
    datasets: [{
      label: 'Setpoint',
      backgroundColor: color(chartColors.blue).alpha(0.5).rgbString(),
			borderColor: chartColors.blue,
      data: []
    }, {
      label: 'Input',
      backgroundColor: color(chartColors.red).alpha(0.5).rgbString(),
			borderColor: chartColors.red,
      data: []
    }]
  },
  options: {
    animation: {
      duration: 0, // general animation time
    },
    scales: {
      xAxes: [{
        type: 'realtime',
        realtime: {
          duration: 40000,
          refresh: 500, // this needs to be faster than the controller loop
          delay: 2000
        }
      }],
      yAxes: [{
        scaleLabel: {
          display: true
        },
        ticks: {
          min: 0,
          max: 100
        }
      }]
    },
    elements: {
      line: {
        borderWidth: 2,
        fill: false,
        tension: 0.3,
        stepped: true
      },
      point: {
        radius: 0
      }
    }
  }
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
