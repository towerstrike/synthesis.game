import Foundation
import GameController

public struct ControllerState {
    var leftStickX: Float = 0
    var leftStickY: Float = 0
    var rightStickX: Float = 0
    var rightStickY: Float = 0
    var leftTrigger: Float = 0
    var rightTrigger: Float = 0
    var buttonA: Bool = false
    var buttonB: Bool = false
    var buttonX: Bool = false
    var buttonY: Bool = false
}

public class Controller {
    private var gcController: GCController?

    init() {
        GCController.startWirelessControllerDiscovery()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        // Try to get first available controller
        gcController = GCController.controllers().first
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func controllerDidConnect(_ notification: Notification) {
        if gcController == nil {
            gcController = notification.object as? GCController
        }
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        if let disconnected = notification.object as? GCController,
            disconnected === gcController
        {
            gcController = GCController.controllers().first
        }
    }

    public var isConnected: Bool {
        return gcController != nil
    }

    public func readState() -> ControllerState {
        var state = ControllerState()

        guard let gamepad = gcController?.extendedGamepad else {
            return state
        }

        state.leftStickX = gamepad.leftThumbstick.xAxis.value
        state.leftStickY = gamepad.leftThumbstick.yAxis.value
        state.rightStickX = gamepad.rightThumbstick.xAxis.value
        state.rightStickY = gamepad.rightThumbstick.yAxis.value
        state.leftTrigger = gamepad.leftTrigger.value
        state.rightTrigger = gamepad.rightTrigger.value
        state.buttonA = gamepad.buttonA.isPressed
        state.buttonB = gamepad.buttonB.isPressed
        state.buttonX = gamepad.buttonX.isPressed
        state.buttonY = gamepad.buttonY.isPressed

        return state
    }
}
