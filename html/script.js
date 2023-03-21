function SendData(data, cb) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
            if (cb) {
                cb(xhr.responseText)
            }
        }
    }
    xhr.open("POST", 'https://renzu_steeringwheel/nuicb', true)
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify(data))
}


let lastgear = 0
let gear = 0
let SteeringWheel = false;
let hasWheels = false;
let handbrake = 0;
let InvervalID = undefined

const gears = {
    ['12']: true,
    ['13']: true,
    ['14']: true,
    ['15']: true,
    ['16']: true,
    ['17']: true,
    ['18']: true,
}
const SteeringWheelsApi = () => {
    let GamePadApi = navigator.getGamepads() || [];
    for (let gamepad of GamePadApi) {
        if (gamepad) {
            if (gamepad.id.match(/g29/i)) {
                SteeringWheel = gamepad
                break;
            }
        }
    }
    if (SteeringWheel && SteeringWheel.id.match(/g29/i)) {
        let WheelAxis = SteeringWheel.axes[0];
        let GasPedal = SteeringWheel.axes[2];
        let BrakePedal = SteeringWheel.axes[5];
        let ClutchPedal = SteeringWheel.axes[1];
        WheelAxis = WheelAxis < 0.0 && Math.abs(WheelAxis) || -Math.abs(WheelAxis)
        GasPedal = (GasPedal * -1 + 1) / 2;
        BrakePedal = (BrakePedal * -1 + 1) / 2;
        ClutchPedal = (ClutchPedal * -1 + 1) / 2;

        for (let index = 0; index < 23; index++) {
            let button = SteeringWheel.buttons[index];
            if (button.value == 1 && gears[index]) {
                if (lastgear == 0) {
                    if (hasWheels == true) {
                        gear = index - 11;
                    }
                    lastgear = index
                } else {
                    if (lastgear != index) {
                        lastgear = 0
                    }
                }
            } else if (button.value == 1 && index == 3) {
                handbrake = 1;
            } else if (button.value == 1 && index == 2) {
                SendData({ nitro: 1, msg: 'api' })
            } else if (button.value == 0 && lastgear == index) {
                if (lastgear > 0) {
                    gear = 0;
                    lastgear = 0;
                }
            } else if (button.value == 1 && index == 5) {
                SendData({ rightsignal: 1, leftsignal: 0, msg: 'api' })
            } else if (button.value == 1 && index == 4) {
                SendData({ leftsignal: 0, rightsignal: 1, msg: 'api' })
            } else if (button.value == 0 && index == 3 && handbrake == 1) {
                handbrake = 0;
            }
        }
        if (hasWheels) {
            SendData({ wheel: WheelAxis, throttle: GasPedal, brake: BrakePedal, clutch: ClutchPedal, gear: gear, handBrake: handbrake, msg: 'api' })
        }
    }
}

window.addEventListener('message', (event) => {
    if (SteeringWheel) {
        if (event.data.apistart) {
            hasWheels = true
            InvervalID = setInterval(function() {
                SteeringWheelsApi()
            }, 5)
        } else if (!event.data.apistart) {
            clearInterval(InvervalID);
            hasWheels = false
        }
    }
});

window.addEventListener("gamepadconnected", (e) => {
    const gp = navigator.getGamepads()[e.gamepad.index];
    console.log(
        `Gamepad connected at index ${gp.index}: ${gp.id} with ${gp.buttons.length} buttons, ${gp.axes.length} axes.`
    );
    SteeringWheel = gp
})