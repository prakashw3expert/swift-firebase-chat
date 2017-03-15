//
//  InboxVCCell.swift
//  HeyU
//
//  Created by Bekground on 24/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class InboxVCCell: UITableViewCell {

    @IBOutlet var lableTime: UILabel!
    @IBOutlet var userimage: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var lastmessage: UILabel!
    var mobile: String?
    @IBOutlet var lblunreadcount: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.userimage.layer.cornerRadius = userimage.frame.size.width / 2
        self.userimage.clipsToBounds = true
        
        self.lblunreadcount.layer.cornerRadius = 13
        self.lblunreadcount.clipsToBounds = true
        
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
