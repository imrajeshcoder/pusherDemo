//
//  ViewController.swift
//  PusherDemo
//
//  Created by Rajesh Shiyal on 15/02/22.
//

import UIKit
import PusherSwift
var app_id = "1347734"
var key = "dc5580c33c288367d551"
var secret = "c5cbfc31dc7f7130568a"
var cluster = "ap2"
class ViewController: UIViewController, PusherDelegate {
    var pusher: Pusher!
    var channel :  PusherChannel?
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let options = PusherClientOptions(
//            host: .cluster("ap2")
//        )
        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder()),
            host: .cluster("ap2")
        )
        pusher = Pusher(
            key: "dc5580c33c288367d551",
            options: options
        )
        pusher.delegate = self
        // subscribe to channel
        
        //MARK: - pushar call back event
        // bind a callback to handle an event
        
        pusher.connect()
        
        initialSetup()
    }
    //MARK: - initial setup
    func initialSetup()  {
        pusherSetup()
    }
    func pusherSetup() {
        // bind to all events globally
        _ = pusher.bind(eventCallback: { (event: PusherEvent) in
            var message = "Received event: '\(event.eventName)'"
            
            if let channel = event.channelName {
                message += " on channel '\(channel)'"
            }
            if let userId = event.userId {
                message += " from user '\(userId)'"
            }
            if let data = event.data {
                message += " with data '\(data)'"
            }
            
            print(message)
        })
        channel = pusher.subscribe("my-channel")
        let _ = channel?.bind(eventName: "my-event", eventCallback: { (event: PusherEvent) in
            if let data = event.data  {
                // you can parse the data as necessary
                let responseData = self.convertToDictionary(text: data)
                print("Console Message:",responseData?["message"] ?? "")
                //MARK: - Event Trigger
                //
                //                channel.trigger(eventName: "new-comment", data: ["message": "Console Message:\(responseData?["message"] ?? "")"])
            }
        })
//        let channel1 = pusher.subscribe("private-channel")
//        let _ = channel1.bind(eventName: "client-someEventName", eventCallback: { (event: PusherEvent) in
//            if let data = event.data  {
//                // you can parse the data as necessary
//                let responseData = self.convertToDictionary(text: data)
//                print("New Message:",responseData?["message"] ?? "")
//                //MARK: - Event Trigger
//                //
//                //                channel.trigger(eventName: "new-comment", data: ["message": "Console Message:\(responseData?["message"] ?? "")"])
//            }
//        })
        
    }
    
    // PusherDelegate methods
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // print the old and new connection states
        print("old: \(old.stringValue()) -> new: \(new.stringValue())")
    }
    
    func subscribedToChannel(name: String) {
        print("Subscribed to \(name)")
    }
    
    func debugLog(message: String) {
        print(message)
    }
    
    func receivedError(error: PusherError) {
        if let code = error.code {
            print("Received error: (\(code)) \(error.message)")
        } else {
            print("Received error: \(error.message)")
        }
    }
    
    //MARK: -  Convert Dictionary
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    @IBAction func btnAction_SendMessage(_ sender: UIButton) {
        pusher.unsubscribeAll()
        let chan  = pusher.subscribe("private-channel")

        // triggers a client event on that channel
        chan.trigger(eventName: "client-eventName", data: ["test": "some value"])
        
        //      let  chan = pusher.subscribe(channelName: "private-channel")
        ////        var triggered = chan.trigger(eventName: "client-someEventName", data: ["message": "client trigger event"])
        //        // `binding` is a unique string that can be used to unbind the event callback later
        //        let binding = pusher.bind(eventCallback: { [self] (event: PusherEvent) -> Void in
        //            var triggered = chan.trigger(eventName: "client-someEventName", data: ["message": "client trigger event"])
        //            if event.eventName == "new-comment" {
        //              // Handle the global event
        //            }
        //        })
        
        
        //                // callback for member added event
        //                        let onMemberAdded = { (member: PusherPresenceChannelMember) in
        //                            print(member)
        //                        }
        //
        //                        // subscribe to a presence channel
        //                        let chan = pusher.subscribe("my-channel1", onMemberAdded: onMemberAdded)
        //
        //                        // triggers a client event on that channel
        //                        chan.trigger(eventName: "client-someEventName", data: ["message": "client trigger event"])
    }
}
class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:3030/auth")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
        request.addValue("myToken", forHTTPHeaderField: "Authorization")
        return request
    }
}
