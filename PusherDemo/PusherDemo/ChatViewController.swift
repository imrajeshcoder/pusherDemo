//
//  ChatViewController.swift
//  PusherDemo
//
//  Created by Rajesh Shiyal on 16/02/22.
//


import UIKit
import Alamofire
import PusherSwift
import JSQMessagesViewController
var papp_id = "1347734"
var pkey = "dc5580c33c288367d551"
var psecret = "c5cbfc31dc7f7130568a"
var pcluster = "ap2"

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var pusher : Pusher!
    
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    static let API_ENDPOINT = "http://localhost:4000";
    override func viewDidLoad() {
        super.viewDidLoad()
        let n = Int(arc4random_uniform(1000))
        
        senderId = "anonymous" + String(n)
        print("senderId:",senderId ?? "")
        self.navigationItem.title = senderId
        senderDisplayName = senderId
        inputToolbar.contentView.leftBarButtonItem = nil
        
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        automaticallyScrollsToMostRecentMessage = true
        
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
        
        listenForNewMessages()
    }
    
    private func listenForNewMessages() {
        let options = PusherClientOptions(
            host: .cluster(pcluster)
        )
        
        pusher = Pusher(key: pkey, options: options)
        
        let channel = pusher.subscribe("chatroom")
        let _ = channel.bind(eventName: "new_message", eventCallback: { (event: PusherEvent) in
            if let data = event.data  {
                // you can parse the data as necessary
                let responseData = self.convertToDictionary(text: data)
                print("Console Message:",responseData?["text"] ?? "")
                let author = responseData?["sender"] as! String
                
                if author != self.senderId {
                    let text = responseData?["text"] as! String
                    self.addMessage(senderId: author, name: author, text: text)
                    self.finishReceivingMessage(animated: true)
                }
            }
        })
        pusher.connect()
    }
    
    private func addMessage(senderId: String, name: String, text: String) {
        if let message = JSQMessage(senderId: senderId, displayName: name, text: text) {
            messages.append(message)
        }
    }
    private func postMessage(name: String, message: String) {
        let params: Parameters = ["sender": name, "text": message]
        
        AF.request(ChatViewController.API_ENDPOINT + "/messages", method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
                
            case .success:
                // Succeeded, do something
                print("Succeeded")
            case .failure(let error):
                // Failed, do something
                print(error)
            }
        }
    }
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
}

extension ChatViewController{
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        postMessage(name: senderId, message: text)
        addMessage(senderId: senderId, name: senderId, text: text)
        self.finishSendingMessage(animated: true)
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }
}
