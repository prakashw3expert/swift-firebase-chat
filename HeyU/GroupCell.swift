//
//  GroupCell.swift
//  HeyU
//
//  Created by Bekground on 27/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class GroupCell: UITableViewCell {

    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var totalMembers: UILabel!
    @IBOutlet var createDate: UILabel!
    @IBOutlet var groupName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.groupImage.layer.cornerRadius = 27
        self.groupImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
