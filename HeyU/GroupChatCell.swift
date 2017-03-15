//
//  GroupChatCell.swift
//  HeyU
//
//  Created by Bekground on 31/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class GroupChatCell: UITableViewCell {

    @IBOutlet var messageTop: NSLayoutConstraint!
    @IBOutlet var lead: NSLayoutConstraint!
    @IBOutlet var trail: NSLayoutConstraint!
    @IBOutlet var grayViewHeight: NSLayoutConstraint!
    @IBOutlet var chatArrowRec: UIImageView!
    @IBOutlet var chatArrowSend: UIImageView!
    @IBOutlet var grayChatCellView: UIView!
    @IBOutlet var message: UILabel!
    @IBOutlet var senderName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.grayChatCellView.layer.cornerRadius = 5
        self.grayChatCellView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
