//
//  ContactCell.swift
//  HeyU
//
//  Created by Bekground on 25/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet var friendStatus: UILabel!
    @IBOutlet var friendName: UILabel!
    @IBOutlet var friendImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.friendImage.layer.cornerRadius = 23
        self.friendImage.clipsToBounds = true
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
