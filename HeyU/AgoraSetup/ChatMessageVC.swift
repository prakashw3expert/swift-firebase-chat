//
//  ChatMessageVC.swift
//  HeyU
//
//  Created by BekGround-2 on 10/03/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class ChatMessageVC: UIViewController {
    
    @IBOutlet weak var messageTableView: UITableView!
    
    fileprivate var messageList = [MessageAgora]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "isAnswer")
        UserDefaults.standard.synchronize()
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 24
    }
    
    func append(chat text: String, fromUid uid: Int64) {
        let message = MessageAgora(text: text, type: .chat)
        append(message: message)
    }
    
    func append(alert text: String) {
        let message = MessageAgora(text: text, type: .alert)
        append(message: message)
    }
}


private extension ChatMessageVC {
    func append(message: MessageAgora) {
        messageList.append(message)
        
        var deleted: MessageAgora?
        if messageList.count > 20 {
            deleted = messageList.removeFirst()
        }
        
        updateMessageTable(with: deleted)
    }
    
    func updateMessageTable(with deleted: MessageAgora?) {
        guard let tableView = messageTableView else {
            return
        }
        
        let insertIndexPath = IndexPath(row: messageList.count - 1, section: 0)
        
        tableView.beginUpdates()
        if deleted != nil {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        tableView.insertRows(at: [insertIndexPath], with: .none)
        tableView.endUpdates()
        
        tableView.scrollToRow(at: insertIndexPath, at: .bottom, animated: false)
    }
}

extension ChatMessageVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! ChatMessageCell
        let message = messageList[(indexPath as NSIndexPath).row]
        cell.set(with: message)
        return cell
    }
}
