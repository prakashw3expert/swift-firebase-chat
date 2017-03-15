//
//  ChatCell.swift
//  HeyU
//
//  Created by Bekground on 27/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet var lblMessage: UILabel!
    @IBOutlet var grayViewHeight: NSLayoutConstraint!
    @IBOutlet var lead: NSLayoutConstraint!
    @IBOutlet var trail: NSLayoutConstraint!
    @IBOutlet var grayChatCellView: UIView!
    @IBOutlet var chatArrowSend: UIImageView!
    @IBOutlet var chatArrowRec: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.grayChatCellView.layer.cornerRadius = 5
        self.grayChatCellView.clipsToBounds = true
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
