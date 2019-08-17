import Foundation
import SocketIO
import CoreMotion


struct CustomData : SocketData {
    let tm: Float
    
    func socketRepresentation() -> SocketData {
        return ["time": tm]
    }
}

struct AccData : SocketData{
    let xa: Float
    let ya: Float
    let za: Float
    
    func socketRepresentation() -> SocketData {
        return ["xacc": xa, "yacc": ya, "zacc":za]
    }
}

struct VecThreeData: SocketData{
    let x: Double
    let y: Double
    let z: Double
    
    func socketRepresentation() -> SocketData {
        return ["x": x, "y": y, "z": z]
    }
}
var grobalStr = "test"
var grobalInt: Int = 1

@objcMembers
class SocSwi:NSObject{
    // ファクトリメソッドを定義しておく
    public var motorFlag: Bool = false
    public var testStr: NSString = "ebi kiresou"
    public let manager = SocketManager(socketURL: URL(string: "ws://192.168.100.152:5000")!, config: [.log(true), .compress])
    public var socket: SocketIOClient
    //let socket = manager.defaultSocket
    override init(){
        socket = manager.defaultSocket
    }
    
    func connectSoc(temp:String)->(Void){
        print("============== connect wiht arg =============" + temp)
        self.testStr = "after connection ver2"
    }/*
    socket.on(clientEvent: .connect) {data, ack in
        print("socket connectedfffffffffffffffffffffff")
        NSLog("ffffffffffffffffffffffffffffffffffffffffff")
        self.testStr = "after connection"
    }

    socket.on("currentAmount") {data, ack in
        guard let cur = data[0] as? Double else { return }

        self.socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
            self.socket.emit("update", ["amount": cur + 2.50])
        }

        ack.with("Got your currentAmount", "dude")
    }

    socket.on("testEbi"){data, ack in
        print("testEbi received")

    }

    socket.on("my response"){data, ack in
        print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    }

    socket.on("motor"){data, ack in
        print("Swift Motor On Method!!!--------------------------------------------------")
        self.motorFlag = true
        self.testStr = "motor On"
    }

    socket.connect()
 */
    func emitDate(tm:Float){
        socket.emit("PstateFPS", CustomData(tm:tm));
    }
    
    func emitAcc(xacc:Float, yacc:Float, zacc:Float){
        socket.emit("emitAcc", AccData(xa: xacc, ya: yacc, za: zacc))
    }
    
    func emitVelocity(xVelo: Double, yVelo: Double, zVelo: Double){
        socket.emit("emitVelo", VecThreeData(x: xVelo, y: yVelo, z: zVelo))
    }
    
    func emitLoc(xLoc: Double, yLoc: Double, zLoc: Double){
        socket.emit("emitLoc",  VecThreeData(x: xLoc, y: yLoc, z: zLoc))
    }
    
    func emitPos(yaw: Double, pitch: Double, roll: Double){
        socket.emit("emitPos", VecThreeData(x: yaw, y: pitch, z: roll))
    }
}

class SomeClass:NSObject {
    // ファクトリメソッドを定義しておく
    func doMethod() -> () {
        print("Perform a method!")
    }
}
